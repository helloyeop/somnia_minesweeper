// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MinesweeperV2 {
    address public owner;
    
    // 난이도별 설정
    enum Difficulty { EASY, MEDIUM, HARD }
    
    struct DifficultyConfig {
        uint8 rows;
        uint8 cols;
        uint8 mines;
        uint256 entryFee;
        uint256 winningReward;
    }
    
    mapping(Difficulty => DifficultyConfig) public difficultyConfigs;
    
    struct Game {
        address player;
        Difficulty difficulty;
        uint8 rows;
        uint8 cols;
        uint8 totalTiles;
        uint8 mineCount;
        mapping(uint8 => uint8) board; // position => value (0: empty, 1-8: adjacent mines, 9: mine)
        mapping(uint8 => bool) revealed;
        mapping(uint8 => bool) flagged;
        uint8 revealedCount;
        bool gameOver;
        bool won;
        uint256 startTime;
        uint256 minePositions; // bit field for mine positions
    }
    
    mapping(address => Game) public games;
    mapping(address => uint256) public playerScores;
    mapping(address => mapping(Difficulty => uint256)) public playerWinsByDifficulty;
    mapping(address => uint256) public totalPlayerWins;
    
    event GameStarted(address indexed player, Difficulty difficulty);
    event TileRevealed(address indexed player, uint8 position);
    event TileFlagged(address indexed player, uint8 position, bool flagged);
    event GameOver(address indexed player, bool won, uint256 score, Difficulty difficulty);
    
    modifier onlyInGame() {
        require(games[msg.sender].player == msg.sender && !games[msg.sender].gameOver, "Not in active game");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        
        // 초급: 9x9, 10개 지뢰
        difficultyConfigs[Difficulty.EASY] = DifficultyConfig({
            rows: 9,
            cols: 9,
            mines: 10,
            entryFee: 0.0005 ether,
            winningReward: 0.001 ether
        });
        
        // 중급: 16x16, 40개 지뢰
        difficultyConfigs[Difficulty.MEDIUM] = DifficultyConfig({
            rows: 16,
            cols: 16,
            mines: 40,
            entryFee: 0.001 ether,
            winningReward: 0.003 ether
        });
        
        // 고급: 16x30, 99개 지뢰
        difficultyConfigs[Difficulty.HARD] = DifficultyConfig({
            rows: 16,
            cols: 30,
            mines: 99,
            entryFee: 0.002 ether,
            winningReward: 0.008 ether
        });
    }
    
    function startGame(Difficulty difficulty) external payable {
        DifficultyConfig memory config = difficultyConfigs[difficulty];
        require(msg.value >= config.entryFee, "Insufficient entry fee");
        require(games[msg.sender].player == address(0) || games[msg.sender].gameOver, "Game already in progress");
        
        // Initialize new game
        Game storage game = games[msg.sender];
        game.player = msg.sender;
        game.difficulty = difficulty;
        game.rows = config.rows;
        game.cols = config.cols;
        game.totalTiles = config.rows * config.cols;
        game.mineCount = config.mines;
        game.revealedCount = 0;
        game.gameOver = false;
        game.won = false;
        game.startTime = block.timestamp;
        
        // Clear previous game data
        for (uint8 i = 0; i < game.totalTiles; i++) {
            delete game.board[i];
            delete game.revealed[i];
            delete game.flagged[i];
        }
        
        // Generate mines using pseudo-random positions
        uint256 minePositions = 0;
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao)));
        uint8 minesPlaced = 0;
        
        while (minesPlaced < config.mines) {
            uint8 position = uint8(seed % game.totalTiles);
            seed = uint256(keccak256(abi.encodePacked(seed)));
            
            if ((minePositions & (1 << position)) == 0) {
                minePositions |= (1 << position);
                game.board[position] = 9; // Mine
                minesPlaced++;
            }
        }
        
        game.minePositions = minePositions;
        
        // Calculate numbers for non-mine tiles
        for (uint8 i = 0; i < game.totalTiles; i++) {
            if (game.board[i] != 9) {
                game.board[i] = countAdjacentMines(game, i);
            }
        }
        
        emit GameStarted(msg.sender, difficulty);
    }
    
    function revealTile(uint8 position) external onlyInGame {
        Game storage game = games[msg.sender];
        require(position < game.totalTiles, "Invalid position");
        require(!game.revealed[position], "Tile already revealed");
        require(!game.flagged[position], "Cannot reveal flagged tile");
        
        game.revealed[position] = true;
        game.revealedCount++;
        
        emit TileRevealed(msg.sender, position);
        
        if (game.board[position] == 9) {
            // Hit a mine - game over
            game.gameOver = true;
            game.won = false;
            emit GameOver(msg.sender, false, 0, game.difficulty);
        } else if (game.board[position] == 0) {
            // Empty tile - reveal adjacent tiles
            revealAdjacentTiles(game, position);
        }
        
        // Check win condition
        if (game.revealedCount == (game.totalTiles - game.mineCount) && !game.gameOver) {
            game.gameOver = true;
            game.won = true;
            uint256 score = calculateScore(game);
            playerScores[msg.sender] += score;
            playerWinsByDifficulty[msg.sender][game.difficulty]++;
            totalPlayerWins[msg.sender]++;
            
            // Send reward
            DifficultyConfig memory config = difficultyConfigs[game.difficulty];
            if (address(this).balance >= config.winningReward) {
                payable(msg.sender).transfer(config.winningReward);
            }
            
            emit GameOver(msg.sender, true, score, game.difficulty);
        }
    }
    
    function flagTile(uint8 position) external onlyInGame {
        Game storage game = games[msg.sender];
        require(position < game.totalTiles, "Invalid position");
        require(!game.revealed[position], "Cannot flag revealed tile");
        
        game.flagged[position] = !game.flagged[position];
        emit TileFlagged(msg.sender, position, game.flagged[position]);
    }
    
    function getGameState() external view returns (
        uint8[] memory board,
        bool[] memory revealed,
        bool[] memory flagged,
        bool gameOver,
        bool won,
        Difficulty difficulty,
        uint8 rows,
        uint8 cols
    ) {
        Game storage game = games[msg.sender];
        
        board = new uint8[](game.totalTiles);
        revealed = new bool[](game.totalTiles);
        flagged = new bool[](game.totalTiles);
        
        // Only show board values for revealed tiles or if game is over
        for (uint8 i = 0; i < game.totalTiles; i++) {
            if (game.revealed[i] || game.gameOver) {
                board[i] = game.board[i];
            } else {
                board[i] = 10; // Hidden
            }
            revealed[i] = game.revealed[i];
            flagged[i] = game.flagged[i];
        }
        
        return (board, revealed, flagged, game.gameOver, game.won, game.difficulty, game.rows, game.cols);
    }
    
    function getDifficultyConfig(Difficulty difficulty) external view returns (DifficultyConfig memory) {
        return difficultyConfigs[difficulty];
    }
    
    function getPlayerStats(address player) external view returns (
        uint256 totalScore,
        uint256 totalWins,
        uint256 easyWins,
        uint256 mediumWins,
        uint256 hardWins
    ) {
        return (
            playerScores[player],
            totalPlayerWins[player],
            playerWinsByDifficulty[player][Difficulty.EASY],
            playerWinsByDifficulty[player][Difficulty.MEDIUM],
            playerWinsByDifficulty[player][Difficulty.HARD]
        );
    }
    
    function countAdjacentMines(Game storage game, uint8 position) private view returns (uint8) {
        uint8 count = 0;
        uint8 row = position / game.cols;
        uint8 col = position % game.cols;
        
        for (int8 dr = -1; dr <= 1; dr++) {
            for (int8 dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                
                int8 newRow = int8(row) + dr;
                int8 newCol = int8(col) + dc;
                
                if (newRow >= 0 && newRow < int8(game.rows) && newCol >= 0 && newCol < int8(game.cols)) {
                    uint8 adjPos = uint8(newRow) * game.cols + uint8(newCol);
                    if (game.board[adjPos] == 9) {
                        count++;
                    }
                }
            }
        }
        
        return count;
    }
    
    function revealAdjacentTiles(Game storage game, uint8 position) private {
        uint8 row = position / game.cols;
        uint8 col = position % game.cols;
        
        for (int8 dr = -1; dr <= 1; dr++) {
            for (int8 dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                
                int8 newRow = int8(row) + dr;
                int8 newCol = int8(col) + dc;
                
                if (newRow >= 0 && newRow < int8(game.rows) && newCol >= 0 && newCol < int8(game.cols)) {
                    uint8 adjPos = uint8(newRow) * game.cols + uint8(newCol);
                    if (!game.revealed[adjPos] && !game.flagged[adjPos] && game.board[adjPos] != 9) {
                        game.revealed[adjPos] = true;
                        game.revealedCount++;
                        emit TileRevealed(game.player, adjPos);
                        
                        if (game.board[adjPos] == 0) {
                            revealAdjacentTiles(game, adjPos);
                        }
                    }
                }
            }
        }
    }
    
    function calculateScore(Game storage game) private view returns (uint256) {
        uint256 timeTaken = block.timestamp - game.startTime;
        uint256 baseScore = 1000;
        
        // Difficulty multiplier
        uint256 multiplier = 1;
        if (game.difficulty == Difficulty.MEDIUM) {
            multiplier = 3;
        } else if (game.difficulty == Difficulty.HARD) {
            multiplier = 10;
        }
        
        baseScore *= multiplier;
        
        // Reduce score based on time taken (lose 1 point per second)
        if (timeTaken < baseScore) {
            return baseScore - timeTaken;
        }
        return multiplier;
    }
    
    function withdraw() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }
    
    receive() external payable {}
}