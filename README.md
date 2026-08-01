# Reproducible Docker Workstation Lab

Docker-in-Docker(DinD) 안에서 개발 워크스테이션 과제를 처음부터 끝까지 재현하는
실행형 문서입니다. 명령을 README에 복사해 나열하는 대신, 주석이 포함된 단계별
셸 스크립트를 단일 진실 공급원(single source of truth)으로 사용합니다.

> 현재 상태: **자동 검증 및 브라우저 golden 검토 완료**
>
> 단계별 Bash 파일 자체가 명령, 출력 조건, 실패 조건을 포함하는 실행형 기술
> 문서입니다. `bash lab.bash run`의 종료 코드가 전체 검증 결과입니다.

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
    ├── /mnt/host-bind-mount-volume # 실제 호스트 volumes/bind-mount/
    ├── Docker daemon           # 실습 이미지/컨테이너/볼륨
    ├── .local/evidence/        # ignored runtime output
    └── scripts/*.bash          # 실행 가능한 기술 문서
        └── nested containers   # hello-world, ubuntu, nginx, Chromium
```

- 호스트 환경을 오염시키지 않도록 Git 설정, 권한 실습, 컨테이너 운영을 DinD 안에
  격리합니다.
- `docker compose exec` 대신 `bash lab.bash`를 공개 인터페이스로 두어 실행 방법을 고정합니다.
- 스크립트는 명령을 출력하고 결과를 assertion으로 검증합니다. 생성 로그는 같은
  내용을 중복하므로 저장소에 커밋하지 않고 CI 출력으로만 보존합니다.
- 주소창 포함 브라우저 증거는 실제 Chromium/Xvfb 화면에서 자동 생성해 검토된
  golden file과 binary diff합니다.
- 바인드 마운트는 실행 시 생성한 실제 호스트 `./volumes/bind-mount`를 outer container의
  `/mnt/host-bind-mount-volume`에 연결하고, nested container가 그 outer 경로를
  다시 마운트하는 2단 구조입니다.

## 파일 구성과 존재 이유

| 파일 | 독립 파일인 이유 |
|---|---|
| `README.md` | GitHub 제출 화면에서 전체 설계와 검증 진입점을 제공 |
| `.gitignore` | 소스와 재생성 가능한 `.local/`, `volumes/`를 분리 |
| `compose.yaml` | outer DinD의 build, 권한, 포트, 저장소 연결을 선언 |
| `lab.bash` | 런타임 디렉터리 생성과 단계 순서를 소유하는 단일 사용자 인터페이스 |
| `app/Dockerfile` | 과제에서 직접 작성을 요구한 커스텀 이미지 recipe |
| `app/index.html` | 이미지에 포함되는 실제 웹 서버 콘텐츠 |
| `scripts/lib.bash` | 모든 검증 단계의 출력 형식, HTTP 대기, cleanup 중복 제거 |
| `scripts/10-cli-and-permissions.bash` | 파일 조작과 권한 요구사항을 독립 재실행 |
| `scripts/20-environment-and-docker.bash` | 실행 환경과 Docker 기본 운영을 한 번만 점검 |
| `scripts/30-custom-image.bash` | 이미지 build, port mapping, HTTP 검증 |
| `scripts/40-storage.bash` | bind mount와 named volume의 서로 연결된 저장소 검증 |
| `scripts/50-git.bash` | disposable outer 환경의 Git 설정과 remote 검증 |
| `scripts/60-browser-evidence.bash` | 실제 브라우저 캡처와 binary regression의 원자적 절차 |
| `tests/browser/README.md` | 버전·raster 입력 고정처럼 비직관적인 결정의 근거 |
| `tests/expected/browser-with-address-bar.png` | 명시적 제출 증거이자 검토된 regression golden |

빈 디렉터리를 보존하기 위한 `.gitkeep`은 두지 않습니다. `volumes/`와 `.local/`은
`lab.bash`가 필요할 때 만들며, 삭제해도 다음 실행에서 복구됩니다.

## 수행 체크리스트

- [x] 터미널 기본 조작 (`scripts/10-cli-and-permissions.bash`)
- [x] 파일·디렉터리 권한 변경 전후 비교 (`scripts/10-cli-and-permissions.bash`)
- [x] 실행 환경과 Docker 버전·데몬 점검 (`scripts/20-environment-and-docker.bash`)
- [x] 이미지/컨테이너/로그/stats 운영 명령 (`scripts/20-environment-and-docker.bash`)
- [x] hello-world 및 Ubuntu 컨테이너 실습 (`scripts/20-environment-and-docker.bash`)
- [x] 커스텀 NGINX 이미지 빌드·실행 (`scripts/30-custom-image.bash`)
- [x] 포트 매핑과 curl 검증 (`scripts/30-custom-image.bash`)
- [x] 실제 호스트를 관통하는 바인드 마운트 변경 반영 (`scripts/40-storage.bash`)
- [x] Docker 볼륨 영속성 (`scripts/40-storage.bash`)
- [x] Git 설정 검증 (`scripts/50-git.bash`)
- [x] 주소창 포함 Chromium binary regression (`scripts/60-browser-evidence.bash`)
- [ ] VS Code GitHub 로그인 화면(최종 제출 시 수동 확인)

## 실행형 기술 문서와 검증

README에 명령 출력을 복제하지 않습니다. 아래 스크립트가 수행 명령을 출력하고,
기대 결과가 다르면 즉시 non-zero로 종료합니다. 따라서 문서와 실제 검증 절차가
서로 달라지는 문제를 방지합니다.

| 검증 대상 | 실행 문서 | 주요 assertion |
|---|---|---|
| CLI와 권한 | [`scripts/10-cli-and-permissions.bash`](scripts/10-cli-and-permissions.bash) | `600→644`, `700→755` |
| 실행 환경과 Docker 운영 | [`scripts/20-environment-and-docker.bash`](scripts/20-environment-and-docker.bash) | 버전, daemon, foreground/exec, logs, stats |
| 이미지와 포트 | [`scripts/30-custom-image.bash`](scripts/30-custom-image.bash) | HTTP 200, image/container 상태 |
| 마운트와 볼륨 | [`scripts/40-storage.bash`](scripts/40-storage.bash) | 즉시 변경 반영, 삭제 후 데이터 유지 |
| Git | [`scripts/50-git.bash`](scripts/50-git.bash) | 필수 설정과 remote |
| 브라우저 UI | [`scripts/60-browser-evidence.bash`](scripts/60-browser-evidence.bash) | 주소창 URL, PNG binary equality |

브라우저 버전을 포함한 재현성 입력을 고정한 이유와 artifact lifecycle은
[`tests/browser/README.md`](tests/browser/README.md)에 설명합니다.

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

## UI 증거

주소창과 응답 화면은 headless page screenshot이 아니라 Xvfb에서 실행한 실제 Chromium
창 전체를 캡처합니다. 검토 완료 후 아래 golden image가 기술 문서의 제출 증거이자
binary regression 기준이 됩니다.

![주소창을 포함한 포트 매핑 증거](tests/expected/browser-with-address-bar.png)

VS Code GitHub 로그인은 인증 UI이므로 자동화하거나 토큰을 캡처하지 않습니다. 최종
제출 시 계정 식별자와 알림을 가린 화면을 별도로 검토합니다.

## 트러블슈팅 기록

### 1. DinD 안의 바인드 마운트 파일이 보이지 않음

- 문제: nested container에 호스트 경로를 연결했지만 파일이 비어 있음
- 원인 가설: bind source를 해석하는 주체는 Docker CLI가 아니라 DinD daemon임
- 확인: outer container에서 해당 절대 경로의 존재 여부 확인
- 해결: 실제 호스트 `./volumes/bind-mount`를 outer container의 `/mnt/host-bind-mount-volume`에 연결하고 nested container에는
  동일한 `/mnt/host-bind-mount-volume`을 연결

### 2. 종료한 컨테이너의 데이터가 사라짐

- 문제: 새 컨테이너에서 이전 파일을 찾을 수 없음
- 원인 가설: 파일을 컨테이너 writable layer에만 저장함
- 확인: 동일 named volume을 연결했는지 `docker inspect`로 확인
- 해결: named volume을 생성해 두 컨테이너의 `/data`에 차례로 연결하고 파일 유지 검증

실제 수행 중 다른 문제가 발생하면 가설, 확인 명령, 해결 또는 대안을 같은 형식으로
추가합니다.

## 보안 점검

커밋 전 tracked 문서와 승인할 golden image 주변 파일에서 다음 패턴을 확인합니다.

```bash
git grep -n -i -E '(token|password|passwd|secret|authorization:|private key)'
```

Git 설정 출력에는 값이 노출될 수 있는 `--list` 전체 대신 과제에 필요한 키만
선택적으로 출력합니다.
