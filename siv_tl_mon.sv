
class siv_tl_mon extends uvm_monitor;
  `uvm_component_utils(siv_tl_mon)
  `uvm_new_func

  virtual siv_tl_if rc_if;

  siv_pcie_tl_sequence_items seq;

  bit [31:0]tx_data[$];
  //   bit [31:0]rx_data[$];

  int pkt_len;

  uvm_analysis_port#(siv_pcie_tl_sequence_items) mon_port;

  function void build;
    seq= siv_pcie_tl_sequence_items::type_id::create("seq");
    mon_port=new("mon_port",this);
    uvm_config_db#(virtual siv_tl_if)::get(this, "", "vif", rc_if);
  endfunction


  task run_phase(uvm_phase phase);
    forever
      begin
        wait(rc_if.rst==0);
        @(posedge rc_if.clk)
        #0;

        //                 `uvm_info("mon enter",$sformatf("data %0h",rc_if.tx_data),UVM_NONE)

        if(rc_if.tx_data && (rc_if.tx_data[31:29] inside {0,1,2,3})) //its a write or read TLP as for now
          begin
//             `uvm_info("mon enter","hello",UVM_NONE)
            tx_data.push_back(rc_if.tx_data);
            `pkt_len(tx_data[0][30], tx_data[0][29], tx_data[0][9:0], tx_data[0][15])

            for(int i=0; i < pkt_len-1; i++)
              begin
                @(posedge rc_if.clk)
                #0
                tx_data.push_back(rc_if.tx_data);
                //                                 `uvm_info("tx_data updata",$sformatf("data is %p",tx_data),UVM_NONE)
              end

            if(tx_data[0][28:24]==0)// 3dw, 4dw mem
              begin
                seq.pkt_type=2;
                if(tx_data[0][29]==0)
                  seq.header_mem={tx_data[0],tx_data[1],32'h0,tx_data[2]};
                else
                  seq.header_mem={tx_data[0],tx_data[1],tx_data[2],tx_data[3]};
                seq.payload_m={tx_data[(tx_data[0][31:29] == 2 ? 3 : 4):($-(seq.header_mem.td))]};
                
//                 `uvm_info("monitor mem check", $sformatf("tx_data %p",tx_data),UVM_NONE);
//                 `uvm_info("monitor mem check", $sformatf("seq_header_mem %p",seq.header_mem),UVM_NONE);
              end
            else if(tx_data[0][28:24]==2)//io
              begin
                seq.header_io={tx_data[0],tx_data[1],tx_data[2]};
                seq.pkt_type=3;
                seq.payload_m={tx_data[3:($-(seq.header_io.td))]}; 
              end
            else if(tx_data[0][28:24]==4)//config
              begin
                seq.header_config={tx_data[0],tx_data[1],tx_data[2]};
                seq.payload_m={tx_data[3:($-(seq.header_config.td))]}; 
                seq.pkt_type=1;
              end
            else if(tx_data[0][28:24]==10)//cpl
              begin
                `uvm_info("comp_payload check",$sformatf("completion header %p",seq.header_cpl),UVM_NONE)
                seq.header_cpl={tx_data[0],tx_data[1],tx_data[2]};
                seq.payload_m={tx_data[3:($-(seq.header_cpl.td))]}; 
                seq.pkt_type=4;
              end


            //             seq.payload_m={tx_data[3:($-1)]};//only applicable for 3dw change needed for 4dw
            if(tx_data[15])
              seq.ecrc=tx_data[$];
            else
              seq.ecrc=0;

//             `uvm_info("Mon Seq pkt",$sformatf("seq pkt %p",seq),UVM_NONE)

//             `uvm_info("Mon Total pkt",$sformatf("%0d full pkt %p",pkt_len,tx_data),UVM_NONE)
            mon_port.write(seq);
            tx_data.delete();
//             `uvm_info("tx_data updata",$sformatf("data is %p",tx_data),UVM_NONE)

          end

      end

  endtask



endclass



