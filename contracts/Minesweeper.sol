// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Minesweeper {
    address public owner;
    uint256 public constant BOARD_SIZE = 64; // 8x8 board
    uint256 public constant MINE_COUNT = 10;
    uint256 public constant ENTRY_FEE = 0.001 ether;
    uint256 public constant WINNING_REWARD = 0.002 ether;
    
    struct Game {
        address player;
        uint256[64] board; // 0: empty, 1-8: number of adjacent mines, 9: mine
        bool[64] revealed;
        bool[64] flagged;
        uint256 revealedCount;
        bool gameOver;
        bool won;
        uint256 startTime;
        uint256 minePositions;
    }
    
    mapping(address => Game) public games;
    mapping(address => uint256) public playerScores;
    mapping(address => uint256) public playerWins;
    
    event GameStarted(address indexed player);
    event TileRevealed(address indexed player, uint8 position);
    event TileFlagged(address indexed player, uint8 position, bool flagged);
    event GameOver(address indexed player, bool won, uint256 score);
    
    modifier onlyInGame() {
        require(games[msg.sender].player == msg.sender && !games[msg.sender].gameOver, "Not in active game");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function startGame() external payable {
        require(msg.value >= ENTRY_FEE, "Insufficient entry fee");
        require(games[msg.sender].player == address(0) || games[msg.sender].gameOver, "Game already in progress");
        
        // Initialize new game
        Game storage game = games[msg.sender];
        game.player = msg.sender;
        game.revealedCount = 0;
        game.gameOver = false;
        game.won = false;
        game.startTime = block.timestamp;
        
        // Clear board
        for (uint8 i = 0; i < BOARD_SIZE; i++) {
            game.board[i] = 0;
            game.revealed[i] = false;
            game.flagged[i] = false;
        }
        
        // Generate mines using pseudo-random positions
        uint256 minePositions = 0;
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.prevrandao)));
        uint8 minesPlaced = 0;
        
        while (minesPlaced < MINE_COUNT) {
            uint8 position = uint8(seed % BOARD_SIZE);
            seed = uint256(keccak256(abi.encodePacked(seed)));
            
            if ((minePositions & (1 << position)) == 0) {
                minePositions |= (1 << position);
                game.board[position] = 9; // Mine
                minesPlaced++;
            }
        }
        
        game.minePositions = minePositions;
        
        // Calculate numbers for non-mine tiles
        for (uint8 i = 0; i < BOARD_SIZE; i++) {
            if (game.board[i] != 9) {
                game.board[i] = countAdjacentMines(game, i);
            }
        }
        
        emit GameStarted(msg.sender);
    }
    
    function revealTile(uint8 position) external onlyInGame {
        require(position < BOARD_SIZE, "Invalid position");
        require(!games[msg.sender].revealed[position], "Tile already revealed");
        require(!games[msg.sender].flagged[position], "Cannot reveal flagged tile");
        
        Game storage game = games[msg.sender];
        game.revealed[position] = true;
        game.revealedCount++;
        
        emit TileRevealed(msg.sender, position);
        
        if (game.board[position] == 9) {
            // Hit a mine - game over
            game.gameOver = true;
            game.won = false;
            emit GameOver(msg.sender, false, 0);
        } else if (game.board[position] == 0) {
            // Empty tile - reveal adjacent tiles
            revealAdjacentTiles(game, position);
        }
        
        // Check win condition
        if (game.revealedCount == BOARD_SIZE - MINE_COUNT && !game.gameOver) {
            game.gameOver = true;
            game.won = true;
            uint256 score = calculateScore(game);
            playerScores[msg.sender] += score;
            playerWins[msg.sender]++;
            
            // Send reward
            if (address(this).balance >= WINNING_REWARD) {
                payable(msg.sender).transfer(WINNING_REWARD);
            }
            
            emit GameOver(msg.sender, true, score);
        }
    }
    
    function flagTile(uint8 position) external onlyInGame {
        require(position < BOARD_SIZE, "Invalid position");
        require(!games[msg.sender].revealed[position], "Cannot flag revealed tile");
        
        games[msg.sender].flagged[position] = !games[msg.sender].flagged[position];
        emit TileFlagged(msg.sender, position, games[msg.sender].flagged[position]);
    }
    
    function getGameState() external view returns (
        uint256[64] memory board,
        bool[64] memory revealed,
        bool[64] memory flagged,
        bool gameOver,
        bool won
    ) {
        Game storage game = games[msg.sender];
        
        // Only show board values for revealed tiles or if game is over
        for (uint8 i = 0; i < BOARD_SIZE; i++) {
            if (game.revealed[i] || game.gameOver) {
                board[i] = game.board[i];
            } else {
                board[i] = 10; // Hidden
            }
        }
        
        return (board, game.revealed, game.flagged, game.gameOver, game.won);
    }
    
    function countAdjacentMines(Game storage game, uint8 position) private view returns (uint256) {
        uint256 count = 0;
        uint8 row = position / 8;
        uint8 col = position % 8;
        
        for (int8 dr = -1; dr <= 1; dr++) {
            for (int8 dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                
                int8 newRow = int8(row) + dr;
                int8 newCol = int8(col) + dc;
                
                if (newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8) {
                    uint8 adjPos = uint8(newRow) * 8 + uint8(newCol);
                    if (game.board[adjPos] == 9) {
                        count++;
                    }
                }
            }
        }
        
        return count;
    }
    
    function revealAdjacentTiles(Game storage game, uint8 position) private {
        uint8 row = position / 8;
        uint8 col = position % 8;
        
        for (int8 dr = -1; dr <= 1; dr++) {
            for (int8 dc = -1; dc <= 1; dc++) {
                if (dr == 0 && dc == 0) continue;
                
                int8 newRow = int8(row) + dr;
                int8 newCol = int8(col) + dc;
                
                if (newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8) {
                    uint8 adjPos = uint8(newRow) * 8 + uint8(newCol);
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
        
        // Reduce score based on time taken (lose 1 point per second)
        if (timeTaken < baseScore) {
            return baseScore - timeTaken;
        }
        return 1;
    }
    
    function withdraw() external {
        require(msg.sender == owner, "Only owner");
        payable(owner).transfer(address(this).balance);
    }
    
    receive() external payable {}
}