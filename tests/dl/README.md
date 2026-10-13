# Data Link Layer tests

Self-checking tests for the DL features this VIP implements. Each test injects
a condition (or none), then checks what the PCIe Base Spec 5.0 requires. The
end of every log has a **DL TEST SUMMARY** block with PASS/FAIL per check.

A failing check means the VIP does something different from the spec. That is
the point of these tests: each failure is a VIP issue to report.

## Who runs what

| Branch | Owner | Tests |
|---|---|---|
| `dl_tests_akash` | Akash Kumar Sahu (M7) | `dl_init_test`, `dl_ack_test`, `dl_lcrc_nak_test`, `dl_lcrc_seq_cover_test` |
| `dl_tests_bhabagrahi` | Bhabagrahi Pradhan (M1) | `dl_replay_timeout_test`, `dl_seq_dup_test`, `dl_seq_skip_test`, `dl_nullified_tlp_test` |
| `dl_tests_mayank` | Kumar Mayank Kashyap (M2) | `dl_dllp_crc_test`, `dl_fc_gating_test`, `dl_state_filter_test`, `dl_fsm_per_device_test` |

All three branches start from `dl_test_infra`, which holds the shared code
(`dl_test_lib.svh`). Each owner only edits their own `dl_tests_<name>.svh`,
so the three branches can later be merged without conflicts.

## How to run (VCS, office server)

```
cd ~/work/PCIe-Gen-5-VIP-prototype
git fetch origin
git checkout -b dl_tests_<name> origin/dl_tests_<name>
bash sim/run_vcs.sh <test_name>
grep -n "DL_INJECT\|DL_CHECK\|DL_TEST_SUMMARY" -A0 sim/out/run.log
```

Copy the log before the next run, because each run overwrites `sim/out/run.log`:
```
cp sim/out/run.log logs_<test_name>.log
```

To see every packet each DL sent, look for the `---- packets sent by RC DL` and
`---- packets sent by EP DL` blocks near the end of the log.

## Tests

| Test | Feature | Injected | Spec rule checked |
|---|---|---|---|
| `dl_init_test` | DLCMSM, DL feature exchange, InitFC | nothing | state order; partner's feature support stored; stored credit limits = advertised |
| `dl_ack_test` | ACK, ACKD_SEQ, replay buffer | nothing | ACK sent for every TLP; ACKD_SEQ = last seq; replay buffer empty; REPLAY_TIMER never expires |
| `dl_lcrc_nak_test` | LCRC check, NAK, replay on NAK | bad LCRC on RC's 1st TLP | EP drops it and NAKs (seq 4095); RC replays seq 0 with good LCRC; EP gets each TLP once |
| `dl_lcrc_seq_cover_test` | LCRC coverage | seq number changed 0 to 5, LCRC kept | EP's LCRC check must fail (LCRC covers the sequence number) |
| `dl_replay_timeout_test` | REPLAY_TIMER, replay buffer | all EP ACKs get a bad CRC | timer expires; all unACKed TLPs replayed, oldest first, same seq and contents |
| `dl_seq_dup_test` | RX duplicate handling | RC's 2nd TLP sent as seq 0 | EP drops the duplicate and ACKs seq 0 |
| `dl_seq_skip_test` | RX out-of-sequence | RC's 1st TLP sent as seq 2 | EP drops it, NAKs seq 4095, gets all TLPs after replay |
| `dl_nullified_tlp_test` | Nullified TLP | inverted LCRC on RC's 1st TLP | EP drops it silently; NEXT_RCV_SEQ unchanged |
| `dl_dllp_crc_test` | DLLP CRC16 check | bad CRC on RC's UpdateFC_P | EP ignores it (P limit stays 32) but applies the good UpdateFC_NP (40) |
| `dl_fc_gating_test` | Flow-control gating | EP gives 1 Posted header credit, RC sends 3 MWr | RC never sends a Posted TLP without a credit |
| `dl_state_filter_test` | DLLP rules per DLCMSM state | RC offers PM_Enter_L1 in FC_INIT1 and in DL_ACTIVE | blocked in FC_INIT1, sent and received in DL_ACTIVE |
| `dl_fsm_per_device_test` | Separate DLCMSM per device | all EP InitFC DLLPs get a bad CRC | RC stays in FC_INIT1, never sends InitFC2, never reaches DL_ACTIVE |

Every test also checks, for RC and EP: DLCMSM reached DL_ACTIVE (except
`dl_fsm_per_device_test`), and NEXT_RCV_SEQ = number of TLPs accepted.

## Observation sheet

Fill one row per test and send it back:

| Test | Compiles? | RESULT | Checks failed (copy the FAIL lines) | Notes |
|---|---|---|---|---|
| | | | | |

## Writing a new test

1. Extend `dl_base_test`.
2. To inject an error: write a class that extends `dl_tx_recorder`, override
   `inject(ref pcie_dl_seq_item item)`, and return it from `make_recorder("RC")`
   or `make_recorder("EP")`. `item.dllp_pkt` holds the DWORDs about to be sent:
   TLP = `{STP, {seq,20'h0}, hdr0, hdr1, hdr2, payload..., LCRC}`,
   DLLP = `{SDP, dllp_dw, {crc16,16'h0}}`.
3. Errors that are the correct reaction to your injection: `catcher.expect_id("ID")`
   in `setup_expected_errors()`. They are counted, not failed.
4. To change sequences: `setup_knobs()` with factory overrides and the static
   knobs of `dl_knob_seq` / `dl_multi_mwr_seq`.
5. In `dl_checks()`, call `dl_check(condition, "what the spec requires", "details")`.
