class siv_pcie_tl_sbd extends uvm_scoreboard;
  `uvm_component_utils(siv_pcie_tl_sbd)
  `uvm_new_func

  `uvm_analysis_imp_decl(_rc)
  `uvm_analysis_imp_decl(_ep)

  bit [31:0] mem[int];

//   bit [31:0] header_first_dw;
  siv_pcie_tl_sequence_items seq;

  bit [31:0] comp_payload[$];

  int ecrc;

  int len,addr;

  siv_pcie_tl_sequence_items os_seq[$];//outstanding request que
  siv_pcie_tl_sequence_items com_seq;


  uvm_analysis_imp_rc #(siv_pcie_tl_sequence_items, siv_pcie_tl_sbd) sbd_imp_rc;

  uvm_analysis_imp_ep #(siv_pcie_tl_sequence_items, siv_pcie_tl_sbd) sbd_imp_ep;

  function void build();
    seq=siv_pcie_tl_sequence_items::type_id::create("seq");

    sbd_imp_rc=new("sbd_imp_rc",this);
    sbd_imp_ep=new("sbd_imp_ep",this);

  endfunction


  function void write_rc(siv_pcie_tl_sequence_items seq);

    `uvm_info("sbd rc seq",$sformatf("payload recieved from mon %p",seq.header_mem),UVM_NONE)
    `uvm_info("sbd rc seq",$sformatf("payload recieved from mon %p",seq.header_io),UVM_NONE)
    `uvm_info("sbd rc seq",$sformatf("payload recieved from mon %p",seq.header_config),UVM_NONE)
//     header_first_dw = seq.header_mem[31:0];

    if(seq.pkt_type == 2 ? seq.header_mem.fmt[1] : (seq.pkt_type == 3 ? seq.header_io.fmt[1] :(seq.pkt_type == 1 ? (seq.header_config.fmt[1]):0))) // check for if it is a 
      begin
        `uvm_info("sbd write","gg",UVM_NONE)
        
        len = seq.pkt_type == 1 ? seq.header_config.len : seq.pkt_type == 2 ? seq.header_mem.len : seq.header_io.len; //calculate len from different pkt type
        addr = seq.pkt_type == 1 ? seq.header_config.reg_no : seq.pkt_type == 2 ? seq.header_mem.address : seq.header_io.address; //calculate address from different pkt type

        for(int i=0;i < len;i++)
          begin
            //             `uvm_info("inside for","jj",UVM_NONE)
            if(seq.header_mem.first_dw==0)seq.payload_m[0]=0;
            else if(seq.header_mem.first_dw==8)seq.payload_m[0][23:0]=0;
            else if(seq.header_mem.first_dw==12)seq.payload_m[0][15:0]=0;
            else if(seq.header_mem.first_dw==14)seq.payload_m[0][7:0]=0;

            if(seq.header_mem.last_dw==0)seq.payload_m[$]=0;
            else if(seq.header_mem.last_dw==1)seq.payload_m[$][31:8]=0;
            else if(seq.header_mem.last_dw==3)seq.payload_m[$][31:16]=0;
            else if(seq.header_mem.last_dw==7)seq.payload_m[$][31:24]=0;

            mem[(addr + i)] = seq.payload_m[i];
            `uvm_info("SBD MEM UPDATE",$sformatf("sbd memory %0p",mem),UVM_NONE)

          end
      end
    else
      begin
        os_seq.push_back(seq);
        `uvm_info("os inc","gg",UVM_NONE)
      end
    //     `uvm_info("SBD MEM UPDATE",$sformatf("sbd memory %0p",mem),UVM_NONE)

    if(seq.pkt_type==1 && seq.header_config.td)
      begin
        ecrc=(seq.header_config[31:0] ^ seq.header_config[63:32] ^ seq.header_config[95:64]);
        if(seq.ecrc!=ecrc)
          `uvm_warning("SBD ECRC FAILED",$sformatf("recieved ecrc = %h	calculated ecrc = %h",seq.ecrc,ecrc));
        if(((seq.header_config.len)!= seq.payload_m.size) && seq.header_config.fmt[1])
          `uvm_warning("SBD Payload size",$sformatf("header len field = %h	recieved payload size = %h",(seq.header_config.len),seq.payload_m.size()));
        
        
        seq=siv_pcie_tl_sequence_items::type_id::create("seq");

      end

    if(seq.pkt_type==2 && seq.header_mem.td)
      begin
        ecrc=(seq.header_mem[31:0] ^ seq.header_mem[63:32] ^ seq.header_mem[95:64]);
        if(seq.ecrc!=ecrc)
          `uvm_warning("SBD ECRC FAILED",$sformatf("recieved ecrc = %h	calculated ecrc = %h",seq.ecrc,ecrc));
        if(((seq.header_mem.len)!= seq.payload_m.size) && seq.header_mem.fmt[1])
          `uvm_warning("SBD Payload size",$sformatf("header len field = %h	recieved payload size = %h",(seq.header_mem.len),seq.payload_m.size()));
        
        
        seq=siv_pcie_tl_sequence_items::type_id::create("seq");

      end
    if(seq.pkt_type==3 && seq.header_io.td)
      begin
        ecrc=(seq.header_io[31:0] ^ seq.header_io[63:32] ^ seq.header_io[95:64]);
        if(seq.ecrc!=ecrc)
          `uvm_warning("SBD ECRC FAILED",$sformatf("recieved ecrc = %h	calculated ecrc = %h",seq.ecrc,ecrc));
        if(((seq.header_io.len)!= seq.payload_m.size) && seq.header_io.fmt[1])
          `uvm_warning("SBD Payload size",$sformatf("header len field = %h	recieved payload size = %h",(seq.header_io.len),seq.payload_m.size()));
        
        
        seq=siv_pcie_tl_sequence_items::type_id::create("seq");

      end
endfunction

  function write_ep(siv_pcie_tl_sequence_items seq);
    int size;
    `uvm_info("ep seq tx",$sformatf("tx seq %p",seq),UVM_NONE)
    `uvm_info("ep outstanding seq",$sformatf("outstanding %p",os_seq),UVM_NONE)

    
    
    
    com_seq=siv_pcie_tl_sequence_items::type_id::create("com_seq");

    if(seq.pkt_type==4 && seq.header_cpl.fmt[1] && os_seq.size > 0)//checking if there is any os request pending
      begin
//         `uvm_info("comp","comp check on the way",UVM_NONE)

        size = os_seq.size;
        
//         `uvm_info("comp payload",$sformatf("recieved completion %p	sbd completion %p",seq.payload_m,comp_payload),UVM_NONE);

        com_seq = os_seq.pop_front();
        if(com_seq.pkt_type == 1)
          begin
            len = com_seq.header_config.len;
            addr = com_seq.header_config.reg_no;
          end
        if(com_seq.pkt_type == 2)
          begin
            len = com_seq.header_mem.len;
            addr = com_seq.header_mem.address;
          end
        if(com_seq.pkt_type == 3)
          begin
            len = com_seq.header_io.len;
            addr = com_seq.header_io.address;
          end

        for(int i=0;i < len; i++)
          begin
//             `uvm_info("inside ep for",$sformatf("len is %0d",len),UVM_NONE)
            comp_payload.push_back(mem[addr+i]);
          end
        
        
        if(comp_payload != seq.payload_m)
          `uvm_warning("COMP MISMATCH",$sformatf("recieved completion %p	sbd completion %p",seq.payload_m,comp_payload));
        
        comp_payload.delete();

        
      end
    //     `uvm_info("SBD MEM UPDATE",$sformatf("sbd memory %0p",mem[1000:1050]),UVM_NONE)

    if(seq.pkt_type==1 && seq.header_config.td)
      begin
        ecrc=(seq.header_config[31:0] ^ seq.header_config[63:32] ^ seq.header_config[95:64]);
        if(seq.ecrc!=ecrc)
          `uvm_warning("SBD ECRC FAILED",$sformatf("recieved ecrc = %h	calculated ecrc = %h",seq.ecrc,ecrc));
        if(((seq.header_config.len)!= seq.payload_m.size) && seq.header_config.fmt[1])
          `uvm_warning("SBD Payload size",$sformatf("header len field = %h	recieved payload size = %h",(seq.header_config.len),seq.payload_m.size()));
        
        
        seq=siv_pcie_tl_sequence_items::type_id::create("seq");

      end

    if(seq.pkt_type==2 && seq.header_mem.td)
      begin
        ecrc=(seq.header_mem[31:0] ^ seq.header_mem[63:32] ^ seq.header_mem[95:64]);
        if(seq.ecrc!=ecrc)
          `uvm_warning("SBD ECRC FAILED",$sformatf("recieved ecrc = %h	calculated ecrc = %h",seq.ecrc,ecrc));
        if(((seq.header_mem.len)!= seq.payload_m.size) && seq.header_mem.fmt[1])
          `uvm_warning("SBD Payload size",$sformatf("header len field = %h	recieved payload size = %h",(seq.header_mem.len),seq.payload_m.size()));
        
        
        seq=siv_pcie_tl_sequence_items::type_id::create("seq");

      end
    if(seq.pkt_type==3 && seq.header_io.td)
      begin
        ecrc=(seq.header_io[31:0] ^ seq.header_io[63:32] ^ seq.header_io[95:64]);
        if(seq.ecrc!=ecrc)
          `uvm_warning("SBD ECRC FAILED",$sformatf("recieved ecrc = %h	calculated ecrc = %h",seq.ecrc,ecrc));
        if(((seq.header_io.len)!= seq.payload_m.size) && seq.header_io.fmt[1])
          `uvm_warning("SBD Payload size",$sformatf("header len field = %h	recieved payload size = %h",(seq.header_io.len),seq.payload_m.size()));
        
        
        seq=siv_pcie_tl_sequence_items::type_id::create("seq");

      end
  endfunction

endclass