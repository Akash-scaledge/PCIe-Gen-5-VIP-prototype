# DL Error Recovery – Change Record (NAK, Replay, REPLAY_TIMER, Retrain)

Owner: Bhabagrahi Pradhan (DL team) · Branch: `dl_tests_bhabagrahi`
Line numbers refer to `main` at `5c35f79`.

| Commit | Content | Status |
|---|---|---|
| `33bd3ed` | VIP fixes: Nak generation, nullified TLP, replay engine, REPLAY_NUM rollover, Ack/Nak sequence check, restartable timer | merged to `main` (PR #9) |
| `89c0c4d` | `dl_replay_timeout_test`: bounded ACK corruption, recovery checks | on `dl_tests_bhabagrahi`, PR pending |

Files changed:

| File | Change |
|---|---|
| `src/dl/dlcmsm_driver.sv` | Nak generation, nullified TLP, replay engine, retrain report, Ack/Nak validity |
| `src/common/timer_dl.svh` | timer can be stopped and restarted |
| `tests/dl/dl_tests_bhabagrahi.svh` | `dl_replay_timeout_test` fix (`89c0c4d`) |

---

## 1. Summary of problems found

| # | Problem (before) | Effect |
|---|---|---|
| 1 | Every bad-LCRC TLP scheduled a new Nak | burst of errors → several Naks → several replays |
| 2 | Nullified TLP (inverted LCRC) incremented `NEXT_RCV_SEQ` | next good TLP looked out of sequence → Nak + replay |
| 3 | REPLAY_TIMER expiry replayed from sequence number 0 | wrong start point once sequence numbers moved on |
| 4 | Nak path incremented `REPLAY_NUM` with no rollover check | 4+ Nak replays never reported |
| 5 | A Nak/timeout during a replay overwrote `replay_queue` | replay cut short / restarted mid-way |
| 6 | TLPs acknowledged during a replay were still resent | unnecessary duplicates |
| 7 | Ack/Nak with a sequence number never sent was accepted | replay buffer purged for TLPs that were never acknowledged |
| 8 | Timer expiry cleared `replay_timer_running` *after* the replay restarted it | REPLAY_TIMER could stop running |
| 9 | `timer_uvm_dl`: `start_timer()` right after `stop_timer()` was ignored, and the stopped countdown never expired | REPLAY_TIMER and the AckNak latency timer silently dead after the first ACK or LCRC error |
| 10 | `dl_replay_timeout_test` corrupted every ACK | endless replays, run ended at UVM_TIMEOUT, no checks/summary |

---

## 2. Nak generation – NAK_SCHEDULED (`dlcmsm_driver.sv`, `dlcmsm_rx`, line ~1347)

**Spec:** on a TLP with a bad LCRC the receiver discards it and, if `NAK_SCHEDULED` is clear, schedules a Nak with `AckNak_Seq_Num = NEXT_RCV_SEQ − 1` and sets `NAK_SCHEDULED`. `NAK_SCHEDULED` is cleared when the next TLP with the expected sequence number is received.

**Before**
```systemverilog
else if (computed_lcrc != received_lcrc) begin
  `uvm_error("LCRC", ...)
  nak_scheduled = 1;
  ack_timer_running = 0;
  acknak_latency_timer.stop_timer();
  schedule_nak(next_rcv_seq - 1);          // every bad TLP -> another Nak
end
```
**After**
```systemverilog
else if (computed_lcrc != received_lcrc) begin
  `uvm_error("LCRC", ...)
  if (!nak_scheduled) begin
    nak_scheduled = 1;
    ack_timer_running = 0;
    acknak_latency_timer.stop_timer();
    schedule_nak(next_rcv_seq - 12'd1);
  end
  else `uvm_info("LCRC", "NAK already scheduled - no new NAK", UVM_LOW)
end
```
The same rule for out-of-sequence TLPs was done in the sequence-number fix (Mayank, `12c69f6`).

## 3. Nullified TLP (`dlcmsm_rx`, line ~1340)

**Spec:** a TLP whose LCRC is the inverse of the computed LCRC is a nullified TLP: discarded silently, no Ack/Nak, `NEXT_RCV_SEQ` unchanged.

**Before:** `next_rcv_seq = (next_rcv_seq + 1) % 4096;`
**After:** the increment is removed; the `LCRC` warning now also prints that `NEXT_RCV_SEQ` stays unchanged.

## 4. Replay engine

### 4.1 `start_replay(string reason)` – new common entry (line 548)

Both triggers (Nak and REPLAY_TIMER expiry) now go through one task:

1. **Replay already in progress** → set `replay_requested = 1` and return. The running replay is finished first; one more replay starts when it ends (section 4.4).
2. **Replay buffer empty** → nothing to replay; REPLAY_TIMER is stopped.
3. **`REPLAY_NUM == 11b`** → rollover: `uvm_error("REPLAY_TIMER", ...)` and `force_link_retrain()` (section 5). The replay continues.
4. `REPLAY_NUM = REPLAY_NUM + 1` (11b → 00b on rollover).
5. Replay from the **oldest unacknowledged TLP**: `initiate_buffer_replay(ACKD_SEQ + 1)`.
6. Restart REPLAY_TIMER (`stop_replay_timer(); start_replay_timer();`).

The log line is `"<reason> - replaying from seq_num N, REPLAY_NUM=K"`.

### 4.2 REPLAY_TIMER expiry (`monitor_replay_timer`, `handle_replay_timer_expiration`, lines 509–535)

| Before | After |
|---|---|
| `REPLAY_NUM++`; on rollover error + retrain **and no replay**; else `initiate_buffer_replay()` with default start **0** | `start_replay("REPLAY_TIMER expired")` |
| `replay_timer_running = 0` cleared **after** the handler (killed the restart) | flags cleared **before** the handler |

### 4.3 Nak received (`dlcmsm_rx`, `NAK_DLLP_TYPE`, line ~1580; `handle_nak_replay`, line 1675)

| Before | After |
|---|---|
| no check of `AckNak_Seq_Num` | invalid sequence number → `uvm_error("DL_PROTOCOL")`, Nak discarded (section 6) |
| forward progress → purge, `REPLAY_NUM = 0` | unchanged |
| `REPLAY_NUM++` (no rollover check), then `replay_mode = 1`, replay from `nak_seq + 1`, timer started only if not running | `handle_nak_replay()` → `start_replay("Nak (AckNak_Seq_Num N)")`: rollover check, increment, replay from `ACKD_SEQ + 1`, timer restarted |

### 4.4 Replay in the transmit arbiter (`dlcmsm_tx`, step 2, line 779)

- Before a replayed TLP is sent, `seq_unacked(seq)` is checked. A TLP acknowledged while the replay was running is **not** resent (`REPLAY` info message).
- When `replay_queue` is empty: `replay_mode = 0`; if `replay_requested` is set, it is cleared and `start_replay(...)` is called again.

### 4.5 Helper functions (lines 595–608)

```systemverilog
// AckNak_Seq_Num must be ACKD_SEQ or an unacknowledged TLP
function bit acknak_seq_valid(bit [11:0] seq);
  d           = seq - ACKD_SEQ;
  outstanding = NEXT_TRANSMIT_SEQ - 1 - ACKD_SEQ;   // TLPs sent, not acknowledged
  return (d <= outstanding);                        // 12-bit (mod 4096) arithmetic
endfunction

// TLP 'seq' is still unacknowledged
function bit seq_unacked(bit [11:0] seq);
  return (d != 0 && d <= outstanding);
endfunction
```
Example: `ACKD_SEQ = FFFh`, `NEXT_TRANSMIT_SEQ = 3` (TLPs 0,1,2 sent) → valid Ack/Nak numbers: FFFh, 0, 1, 2.

## 5. Link retrain on REPLAY_NUM rollover (`force_link_retrain`, line 589)

**Spec:** when `REPLAY_NUM` rolls over 11b → 00b, the Physical Layer retrains the link, and the replay follows.

Retrain is **not modelled yet** (agreed): `force_link_retrain()` only reports
```
UVM_ERROR [LINK_RETRAIN] Device N: REPLAY_NUM rollover - link retrain required (not modelled; replay continues)
```
and `start_replay()` also reports `UVM_ERROR [REPLAY_TIMER] ... REPLAY_NUM rollover (11b -> 00b) on <reason>`. The replay then continues so the simulation goes on. Tests that expect a rollover demote both IDs.

**To do (PL/DL):** request Recovery from the LTSSM, wait for it to return to L0, then replay.

## 6. Ack/Nak sequence-number check (`ACK_DLLP_TYPE` line ~1545, `NAK_DLLP_TYPE` line ~1580)

**Spec:** if `AckNak_Seq_Num` is neither `ACKD_SEQ` nor the sequence number of an unacknowledged TLP, the DLLP is discarded and it is a Data Link Layer protocol error.

Both cases now call `acknak_seq_valid()` first and raise
```
UVM_ERROR [DL_PROTOCOL] Device N: Ack|Nak for seq_num S which was never sent (ACKD_SEQ=.. NEXT_TRANSMIT_SEQ=..) - discarded
```
Before, such an Ack within 2048 of `ACKD_SEQ` was treated as forward progress and purged the replay buffer.

## 7. Timer (`src/common/timer_dl.svh`)

**Before**
- `stop_timer()` only set `stop_requested`; `is_running` stayed 1 until the old countdown ran out.
- `start_timer()` returns at once while `is_running` is 1 → a restart right after a stop was ignored.
- The stopped countdown then ended without setting `done_flag` → **the timer never expired again**.

Effects: after an ACK purged part of the replay buffer (`stop_replay_timer(); start_replay_timer();`) REPLAY_TIMER was dead; after an LCRC error stopped the AckNak latency timer, the next good TLP could not restart it, so no more ACKs were sent.

**After** – generation counter:
```systemverilog
int unsigned gen = 0;

function void stop_timer();
  if (is_running) begin
    stop_requested = 1;
    is_running     = 0;   // stops at once
    gen++;                // invalidates the running countdown
  end
endfunction

task start_timer(int delay_cycles, string user_key);
  if (is_running) return;
  ... gen++;
  fork
    automatic int unsigned my_gen = gen;
    begin
      repeat (delay_cycles) @(posedge vif.clk);
      if (my_gen == gen) begin done_flag = 1; is_running = 0; end   // only if not stopped/replaced
    end
  join_none
endtask
```
This class is used by all DL timers (DLCMSM state timer, AckNak latency timer, REPLAY_TIMER).

## 8. Test: `dl_replay_timeout_test` (`tests/dl/dl_tests_bhabagrahi.svh`, commit `89c0c4d`)

**Problem seen on VCS:** EP corrupted **every** ACK (397 in the run). RC never saw forward progress, so REPLAY_TIMER expired every 100 µs and RC replayed forever (REPLAY_NUM rolled over 49 times). Each replay raised an objection inside the 500 µs drain time of `run_PL`, so the run phase never ended: `UVM_FATAL [PH_TIMEOUT]` at 20 ms, `check_phase` never ran, no `DL TEST SUMMARY`.

**Changes**
- `dl_drop_ack_rec`: `static int max_bad_acks = 1` (`< 0` = all) and per-recorder count `n_bad_acks`. ACKs after that are sent good.
- `dl_replay_timeout_test`: `bad_acks` field (default 1), copied to `max_bad_acks` in `setup_knobs()` (static, so set for every test).
- Sizing: EP sends 1 ACK for the original TLPs, then 1 ACK per duplicate TLP in each replay round (2 per round with 2 TLPs outstanding):

  | `max_bad_acks` | Result |
  |---|---|
  | 1 | 1 REPLAY_TIMER expiry, recovery on the first replay |
  | 7 | 4 expiries, REPLAY_NUM rollover (`LINK_RETRAIN` error) |
  | < 0 | every ACK corrupted – endless replays (old behaviour) |

- The check "REPLAY_NUM incremented on replay" read `REPLAY_NUM` at the end of the test; the recovering ACK correctly resets it to 0, so the check would fail on a correct VIP. It now counts `REPLAY_NUM=1` in the replay log.
- New recovery checks: configured number of ACKs corrupted; `ACKD_SEQ` = last TLP sent; RC replay buffer empty; `REPLAY_NUM` back to 0; EP accepted each TLP once.

---

## 9. Tests covering these changes

| Test | Covers |
|---|---|
| `dl_replay_timeout_test` | sections 4.1, 4.2, 4.5, 5, 7 |
| `dl_lcrc_nak_test` (Akash) | section 2, Nak path 4.3, 7 (AckNak timer restart) |
| `dl_seq_dup_test` | duplicate handling, Ack after replay |
| `dl_seq_skip_test` | out-of-sequence Nak, 4.3 |
| `dl_nullified_tlp_test` | section 3 |

Run:
```
bash sim/run_vcs.sh <test>
grep -A40 "DL TEST SUMMARY" sim/out/run.log
```

## 10. Open points

- Link retrain on REPLAY_NUM rollover is reported only (section 5).
- `DL_PROTOCOL` errors should also set the Data Link Protocol Error status once the error-reporting registers are modelled.
- None of these changes has a dedicated test for a Nak/timeout arriving *during* a replay (`replay_requested`, section 4.4).
- Results above are from elaboration and log analysis; re-run all tests in section 9 on VCS after every merge.
