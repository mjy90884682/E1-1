# Why the browser version is pinned

이 디렉터리의 브라우저 검증은 단순히 “페이지가 열렸다”는 사실만 확인하지 않습니다.
과제에서 명시한 **주소창과 응답 화면을 함께 포함한 증거**를 실제 Chromium 창에서
자동 생성하고, 검토된 기준 이미지와 byte-for-byte로 비교합니다.

브라우저 버전, 폰트, 창 크기, device scale factor가 달라지면 서비스 코드가 같아도
글자 rasterization, 브라우저 chrome, PNG 압축 결과가 달라질 수 있습니다. 따라서
`scripts/60-browser-evidence.bash`는 다음을 의도적으로 고정합니다.

- Selenium Chromium image digest:
  `sha256:ddcd01e43742e92eaeb3bc114a01f3e8d6b5afa326ac75aefd57a198d0d20a42`
- Chromium: `138.0.7204.183`
- Xvfb framebuffer: `1365x768x24`
- deterministic capture region: `1365x744` (현재 시간이 표시되는 하단 panel 제외)
- locale/timezone: `ko-KR` / `UTC`
- device scale factor: `1`
- GPU와 X11 mouse cursor 합성 비활성화, 단일 스레드 PNG 압축
- RGB channel을 16단위로 canonicalize하여 최대 1~2 값의 Xvfb raster noise 제거

이 정보는 장식적인 버전 표기가 아니라, binary regression 실패를 제품 변경과 실행
환경 변경 중 어느 쪽에서 찾을지 결정하는 테스트 입력입니다.

## Artifact lifecycle

- `.local/evidence/actual/`: 매 실행에서 생성되는 이미지와 환경 manifest
- `.local/evidence/diff/`: binary mismatch가 발생했을 때의 비교 대상
- `tests/expected/browser-with-address-bar.png`: 사람이 검토하고 승인한 제출 증거이자
  regression golden file

`.local/`은 전부 Git에서 제외합니다. Golden 갱신은 실제 이미지를 열어 주소창,
응답 내용, 민감정보 부재를 검토한 뒤에만 명시적으로 수행합니다.

```bash
bash scripts/60-browser-evidence.bash --update-golden
```

정확히 동일한 환경에서는 binary diff를 사용합니다. 다른 CPU 아키텍처나 커널에서
재생성해야 한다면 무조건 기준 이미지를 덮어쓰지 말고 차이를 먼저 검토합니다.
