# Reproducible Docker Workstation Lab

Docker-in-Docker(DinD) 안에서 개발 워크스테이션 과제를 처음부터 끝까지 재현하는
실행형 문서입니다. 명령을 README에 복사해 나열하는 대신, 주석이 포함된 단계별
셸 스크립트를 단일 진실 공급원(single source of truth)으로 사용합니다.

> 현재 상태: **골격 작성 완료 / 실습 증거 미수집**
>
> 체크 표시는 `bash lab.bash run`을 실행하고 생성된 로그와 수동 증거를 검토한 뒤 갱신합니다.

## 빠른 시작

필수 도구는 Docker Engine(또는 OrbStack)과 Docker Compose 플러그인뿐입니다.

```bash
bash lab.bash up
bash lab.bash run
bash lab.bash down
```

단계 하나만 다시 실행할 수도 있습니다.

```bash
bash lab.bash shell
# DinD 작업실 내부에서:
bash scripts/30-custom-image.bash
```

`bash lab.bash reset`은 컨테이너와 실습용 Docker 볼륨을 삭제하므로 의도적으로 실행해야
합니다. 일반적인 `down`은 DinD 엔진의 데이터를 보존합니다.

## 설계

```text
host (Docker/OrbStack)
└── workstation (privileged DinD outer container)
    ├── /workspace              # 이 저장소
    ├── /mnt/host-bind-mount-volume # 실제 호스트 bind-mount-source/
    ├── Docker daemon           # 실습 이미지/컨테이너/볼륨
    └── scripts/*.bash            # 실행 가능한 기술 문서
        └── nested containers   # hello-world, ubuntu, custom nginx
```

- 호스트 환경을 오염시키지 않도록 Git 설정, 권한 실습, 컨테이너 운영을 DinD 안에
  격리합니다.
- `docker compose exec` 대신 `bash lab.bash`를 공개 인터페이스로 두어 실행 방법을 고정합니다.
- 각 스크립트는 `evidence/logs/<단계>.log`에 명령과 출력을 함께 남깁니다.
- 자동화할 수 없는 브라우저 주소창과 VS Code/GitHub 로그인은
  `evidence/screenshots/`에 별도로 수집합니다.
- 바인드 마운트는 실제 호스트 `./bind-mount-source`를 outer container의
  `/mnt/host-bind-mount-volume`에 연결하고, nested container가 그 outer 경로를
  다시 마운트하는 2단 구조입니다.

## 수행 체크리스트

- [ ] 터미널 기본 조작 (`scripts/10-cli-and-permissions.bash`)
- [ ] 파일·디렉터리 권한 변경 전후 비교 (`scripts/10-cli-and-permissions.bash`)
- [ ] Docker 버전·데몬 점검 (`scripts/20-docker-basics.bash`)
- [ ] 이미지/컨테이너/로그/stats 운영 명령 (`scripts/20-docker-basics.bash`)
- [ ] hello-world 및 Ubuntu 컨테이너 실습 (`scripts/20-docker-basics.bash`)
- [ ] 커스텀 NGINX 이미지 빌드·실행 (`scripts/30-custom-image.bash`)
- [ ] 포트 매핑과 curl 검증 (`scripts/30-custom-image.bash`)
- [ ] 실제 호스트를 관통하는 바인드 마운트 변경 반영 (`scripts/40-storage.bash`)
- [ ] Docker 볼륨 영속성 (`scripts/40-storage.bash`)
- [ ] Git 설정 검증 (`scripts/50-git.bash`)
- [ ] GitHub/VS Code 연동 수동 증거 (`evidence/screenshots/README.md`)

## 실행 환경 및 결과

자동 수집 결과는 실행 후 다음 위치에서 확인합니다.

| 검증 대상 | 실행 문서 | 결과 |
|---|---|---|
| OS, shell, Docker, Git | [`scripts/00-environment.bash`](scripts/00-environment.bash) | `evidence/logs/00-environment.log` |
| CLI와 권한 | [`scripts/10-cli-and-permissions.bash`](scripts/10-cli-and-permissions.bash) | `evidence/logs/10-cli-and-permissions.log` |
| Docker 기본 운영 | [`scripts/20-docker-basics.bash`](scripts/20-docker-basics.bash) | `evidence/logs/20-docker-basics.log` |
| 이미지와 포트 | [`scripts/30-custom-image.bash`](scripts/30-custom-image.bash) | `evidence/logs/30-custom-image.log` |
| 마운트와 볼륨 | [`scripts/40-storage.bash`](scripts/40-storage.bash) | `evidence/logs/40-storage.log` |
| Git | [`scripts/50-git.bash`](scripts/50-git.bash) | `evidence/logs/50-git.log` |

로그는 실행 환경에 따라 달라지는 산출물이므로 첫 골격 커밋에는 포함하지 않습니다.
검증 실행 후 민감정보를 검사한 다음 별도 커밋으로 추가합니다.

## 핵심 개념

- **절대/상대 경로**: `/workspace/app/index.html`은 루트부터 시작하는 절대
  경로이고, 저장소 루트에서의 `app/index.html`은 현재 위치 기준 상대 경로입니다.
- **권한**: `r=4`, `w=2`, `x=1`의 합을 소유자/그룹/기타 순서로 씁니다.
  `755`는 `rwxr-xr-x`, `644`는 `rw-r--r--`입니다.
- **이미지/컨테이너**: 이미지는 불변 실행 템플릿이고 컨테이너는 그 이미지에서
  생성한 격리된 실행 인스턴스입니다.
- **포트 매핑**: 컨테이너 네트워크의 포트는 기본적으로 외부에서 직접 접근할 수
  없으므로 `호스트 포트:컨테이너 포트` 연결이 필요합니다.
- **바인드 마운트/볼륨**: 바인드 마운트는 지정한 파일 경로를 연결해 즉시 변경을
  반영하고, 볼륨은 Docker가 관리하며 컨테이너 수명과 데이터를 분리합니다.
- **Git/GitHub**: Git은 로컬 변경 이력을 관리하는 도구이고 GitHub는 저장소 공유,
  리뷰, 이슈 등 원격 협업을 제공하는 플랫폼입니다.

## 수동 증거

자동 검증 후 아래 이미지를 추가하고 표의 상태를 갱신합니다.

1. `http://localhost:8080` 주소창과 응답 화면
2. VS Code의 GitHub 로그인 및 원격 저장소 연결 화면

캡처 전 토큰, 이메일, 인증 코드, 개인키, 불필요한 사용자 경로를 가립니다.

## 트러블슈팅 기록

### 1. DinD 안의 바인드 마운트 파일이 보이지 않음

- 문제: nested container에 호스트 경로를 연결했지만 파일이 비어 있음
- 원인 가설: bind source를 해석하는 주체는 Docker CLI가 아니라 DinD daemon임
- 확인: outer container에서 해당 절대 경로의 존재 여부 확인
- 해결: 실제 호스트 `./bind-mount-source`를 outer container의 `/mnt/host-bind-mount-volume`에 연결하고 nested container에는
  동일한 `/mnt/host-bind-mount-volume`을 연결

### 2. 종료한 컨테이너의 데이터가 사라짐

- 문제: 새 컨테이너에서 이전 파일을 찾을 수 없음
- 원인 가설: 파일을 컨테이너 writable layer에만 저장함
- 확인: 동일 named volume을 연결했는지 `docker inspect`로 확인
- 해결: named volume을 생성해 두 컨테이너의 `/data`에 차례로 연결하고 파일 유지 검증

실제 수행 중 다른 문제가 발생하면 가설, 확인 명령, 해결 또는 대안을 같은 형식으로
추가합니다.

## 보안 점검

커밋 전 다음 패턴을 로그와 이미지 메타데이터에서 확인합니다.

```bash
rg -n -i '(token|password|passwd|secret|authorization:|private key)' evidence
```

Git 설정 로그에는 값이 노출될 수 있는 `--list` 전체 대신 과제에 필요한 키만
선택적으로 출력합니다.
