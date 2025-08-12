# Somnia Minesweeper - 배포 가이드

## 사전 준비

1. **Node.js 설치**
   ```bash
   # Node.js 18 이상 필요
   node --version
   npm --version
   ```

2. **의존성 설치**
   ```bash
   npm install
   ```

3. **환경 변수 설정**
   ```bash
   # .env.example을 .env로 복사
   cp .env.example .env
   
   # .env 파일에 개인키 입력 (0x 접두사 제외)
   PRIVATE_KEY=your_private_key_here
   ```

## 배포 과정

1. **스마트 컨트랙트 컴파일**
   ```bash
   npm run compile
   ```

2. **Somnia 테스트넷에 배포**
   ```bash
   npm run deploy
   ```

3. **프론트엔드 업데이트**
   - 배포 후 출력된 컨트랙트 주소를 복사
   - `index.html` 파일의 `CONTRACT_ADDRESS` 변수를 업데이트

4. **컨트랙트 검증 (선택사항)**
   ```bash
   npm run verify <CONTRACT_ADDRESS>
   ```

## Somnia 테스트넷 설정

- **네트워크 이름**: Somnia Testnet
- **RPC URL**: https://dream-rpc.somnia.network/
- **체인 ID**: 20537 (0x5039)
- **통화 기호**: ETH
- **블록 익스플로러**: https://somnia-devnet.socialscan.io/

## 테스트넷 토큰 받기

Somnia 테스트넷 토큰을 받으려면:
1. Somnia 공식 디스코드나 커뮤니티에서 faucet 정보 확인
2. 배포 및 게임 플레이를 위해 충분한 테스트 ETH 확보

## 게임 플레이

1. 웹 브라우저에서 `index.html` 열기
2. MetaMask 등 지갑 연결
3. Somnia 테스트넷으로 네트워크 변경
4. "Start New Game" 버튼 클릭 (0.001 ETH 필요)
5. 지뢰찾기 게임 즐기기!

## 게임 규칙

- **보드 크기**: 8x8 (64 타일)
- **지뢰 개수**: 10개
- **입장료**: 0.001 ETH
- **승리 보상**: 0.002 ETH
- **좌클릭**: 타일 공개
- **우클릭**: 깃발 표시/해제

## 문제 해결

1. **배포 실패**: 지갑에 충분한 테스트 ETH가 있는지 확인
2. **게임 시작 불가**: 컨트랙트 주소가 올바르게 설정되었는지 확인
3. **트랜잭션 실패**: 가스 가격 설정 확인