# 🎮 Somnia 지뢰찾기 게임

Somnia 테스트넷에서 작동하는 블록체인 기반 지뢰찾기 게임입니다.

## 📋 목차
- [소개](#소개)
- [주요 기능](#주요-기능)
- [기술 스택](#기술-스택)
- [설치 방법](#설치-방법)
- [게임 방법](#게임-방법)
- [스마트 컨트랙트](#스마트-컨트랙트)


## 🎯 소개

이 프로젝트는 Somnia 블록체인 테스트넷을 활용한 완전한 온체인 지뢰찾기 게임입니다. 모든 게임 로직이 스마트 컨트랙트에서 실행되며, 각 게임의 결과가 블록체인에 영구적으로 기록됩니다.

## ✨ 주요 기능

- **💰 토큰 보상 시스템**: 게임 승리 시 ETH 보상 지급
- **📊 플레이어 통계**: 점수 및 승리 횟수 추적
- **🎮 온체인 게임플레이**: 모든 게임 액션이 블록체인에 기록
- **🏆 리더보드**: 플레이어별 성과 기록
- **📱 반응형 디자인**: 모바일 및 데스크톱 지원

## 🛠 기술 스택

- **블록체인**: Somnia Testnet
- **스마트 컨트랙트**: Solidity ^0.8.20
- **프론트엔드**: HTML5, CSS3, JavaScript
- **Web3 라이브러리**: ethers.js v5
- **개발 도구**: Hardhat, Node.js

## 📦 설치 방법

### 사전 요구사항
- Node.js v18 이상
- MetaMask 지갑
- Somnia 테스트넷 ETH

### 1. 저장소 클론
```bash
git clone https://github.com/helloyeop/somnia_testnet.git
cd somnia_testnet
```

### 2. 의존성 설치
```bash
npm install
```

### 3. 환경 변수 설정
```bash

```
`.env` 파일을 열어 개인키를 입력하세요:
```
PRIVATE_KEY=your_private_key_here
```

### 4. 스마트 컨트랙트 컴파일
```bash
npm run compile
```

### 5. 컨트랙트 배포 (선택사항)
```bash
npm run deploy
```

### 6. 게임 실행
`index.html` 파일을 웹 브라우저에서 열어 게임을 시작하세요.

## 🎮 게임 방법

1. **지갑 연결**: MetaMask를 통해 Somnia 테스트넷에 연결
2. **게임 시작**: 0.001 ETH의 입장료를 지불하고 게임 시작
3. **타일 공개**: 
   - 좌클릭: 타일 공개
   - 우클릭: 깃발 표시/해제
4. **승리 조건**: 지뢰가 없는 모든 타일을 공개

### 게임 규칙
- 보드 크기: 8×8 (64 타일)
- 지뢰 개수: 10개
- 숫자는 인접한 타일의 지뢰 개수를 나타냄

## 📄 스마트 컨트랙트

### 주요 함수
- `startGame()`: 새 게임 시작 (0.001 ETH 필요)
- `revealTile(uint8 position)`: 타일 공개
- `flagTile(uint8 position)`: 타일에 깃발 표시
- `getGameState()`: 현재 게임 상태 조회

### 컨트랙트 주소
- **Somnia Testnet**: `0x448708eBced0886CD6dA771BA45A35265ce6cF05`

## 📁 프로젝트 구조

```
somnia_testnet/
├── contracts/
│   └── Minesweeper.sol      # 지뢰찾기 스마트 컨트랙트
├── scripts/
│   └── deploy.js            # 배포 스크립트
├── index.html               # 게임 UI
├── hardhat.config.js        # Hardhat 설정
├── package.json             # 프로젝트 의존성
├── .env.example             # 환경 변수 예시
├── .gitignore              # Git 제외 파일
├── README.md                # 프로젝트 문서
└── DEPLOYMENT.md            # 배포 가이드
```

## 🔗 Somnia 네트워크 정보

- **네트워크 이름**: Somnia Testnet
- **RPC URL**: https://dream-rpc.somnia.network/
- **체인 ID**: 50312 (0xC488)
- **통화**: SLL
- **블록 익스플로러**: https://shannon-explorer.somnia.network/
