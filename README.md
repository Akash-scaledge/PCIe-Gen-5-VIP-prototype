# PCIe Gen 5 VIP (prototype)
https://edaplayground.com/x/hmPM
UVM VIP for PCIe, verified VIP-to-VIP (RC agent <-> EP agent). Runs on Questa and VCS.

## Folder layout
| Folder | Contents |
|---|---|
| `docs/spec/` | PCIe Base Specification 5.0 v1.0 |
| `src/common/` | Shared defines, parameters, timers, unified cfg (`siv_pcie_cfg.sv`) |
| `src/pl/` | Physical Layer: LTSSM interface, FSM, sequences, driver, coverage, agent |
| `src/dl/` | Data Link Layer: DLCMSM FSM, seq item, driver, agent, DL feature registers |
| `src/tl/` | Transaction Layer: TL interface, seq items, sequences, driver, monitor, agent |
| `src/tl/mem/` | Memory model + memory agent used as EP config/memory space |
| `src/tl/reg/` | Config-space register model (RAL) and adapter |
| `src/*/standalone/` | Per-layer env/test used only by the single-layer testbenches |
| `src/env/` | Full-stack device agent (TL+DL+PL) and top env |
| `tests/` | Full-stack tests |
| `tb/` | Full-stack top: `testbench.sv` (single compile entry) and `pcie_top.sv` |
| `tb/standalone/` | Single-layer testbenches (`testbench_PL/DL/TL.sv`, `top_PL/DL/TL.sv`) |
| `sim/` | Filelist (`vip.f`) and run scripts |
| `misc/` | Scratch/unused files, not compiled |

## How to run (VCS)
```bash
export UVM_HOME=/path/to/uvm-1.2
bash sim/run_vcs.sh            # default test: siv_pcie_base_test
```
Logs go to `sim/out/`.

## Notes
* `` `include `` lines use bare file names; the folders are found through the `+incdir` list in `sim/vip.f`.
  To run on EDA Playground, upload all `.sv/.svh/.svi` files flat (no folders) and it works unchanged.
* New files: put them in the right layer folder and add an `` `include `` in `tb/testbench.sv`.
  If you create a new folder, add a `+incdir+` line for it in `sim/vip.f`.
