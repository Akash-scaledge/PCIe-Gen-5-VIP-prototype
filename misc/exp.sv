//--------------------------------------------------------------
// SIV PCIe Training Sequence Item (siv_pcie_tl_sequence_item)
//--------------------------------------------------------------
//=================SEQ ITEM==================
typedef struct packed{
	bit [2:0]fmt;
	bit [4:0] typef;
	bit reserve1;
	bit [2:0] tc;
	bit reserve2;
	bit attr1;
	bit reserve3;
	bit th;
	bit td;
	bit ep;
	bit [1:0] attr2;
	bit [1:0] at;
	bit [9:0] len;
	bit [15:0] requester_id;
	bit [7:0] tag;
	bit [3:0] last_dw;
	bit [3:0] first_dw;
	bit [7:0] bus_no;
	bit [4:0] dev_no;
	bit [2:0] fun_no;
	bit [3:0] reserve4;
    bit [9:0] reg_no;
	bit [1:0] reserve5;
	}config_header_field;

typedef struct packed{
  bit [2:0]fmt;
  bit [4:0] typef;
  bit reserve1;
  bit [2:0] tc;
  bit reserve2;
  bit attr1;
  bit reserve3;
  bit th;
  bit td;
  bit ep;
  bit [1:0] attr2;
  bit [1:0] at;
  bit [9:0] len;
  bit [15:0] requester_id;
  bit [7:0] tag;
  bit [3:0] last_dw;
  bit [3:0] first_dw;
  //bit [`WIDTH_29:0] address;
  bit [31:0] address;//added directly giving 32 bit address
  //bit [`WIDTH_1:0] reserve5;
  }mem_header_field;//3dw size

typedef struct packed{
  bit [2:0]fmt;
  bit [4:0] typef;
  bit reserve1;
  bit [2:0] tc;
  bit reserve2;
  bit attr1;
  bit reserve3;
  bit th;
  bit td;
  bit ep;
  bit [1:0] attr2;
  bit [1:0] at;
  bit [9:0] len;
  bit [15:0] requester_id;
  bit [7:0] tag;
  bit [3:0] last_dw;
  bit [3:0] first_dw;
  //bit [`WIDTH_29:0] address;
  bit [31:0] address;//added directly giving 32 bit address
  //bit [`WIDTH_1:0] reserve5;
}io_header_field;//3dw size

class siv_pcie_tl_sequence_items extends uvm_sequence_item;
  rand config_header_field header_config;
  rand mem_header_field header_mem;
  rand io_header_field header_io;
  
  rand bit [31:0] prefix[$];
  rand bit [31:0] payload_c[$];
  rand bit [31:0] payload_m[$];	
  rand bit [31:0] payload_i[$];
  static bit [31:0] payload_temp[$];

  
  bit [31:0] ecrc;
  bit [31:0]TLP_c[$];
  bit [31:0]TLP_m[$];
  bit [31:0]TLP_i[$];

  bit [31:0]headerQ[$]; 
  bit [31:0]TLP_storage[$];
  bit [31:0]prefix_temp[$];
  rand bit [9:0] MPS;
  bit [3:0] last_dw_temp;


  
  //flag_type
  rand int pkt_type;  //1 -:config_pkt
                      //2 -:mem_pkt
  					  //3 -:io_pkt
            

  function void post_randomize();		
    //config tx
    if(pkt_type==1)begin
    `uvm_info("siv_pcie_tl_sequence_items","CFG packet",UVM_LOW);
    //formation of the config wr and rd pkt
    if(header_config.typef==4 && (header_config.fmt==2 || header_config.fmt==0))begin
      
      for(int i=0;i<3;i++) begin
        headerQ.push_front(header_config[32*i+:32]);// for temporary storage
      end
      if(prefix[0][28]==1)begin
     	prefix_temp={prefix,headerQ};
	  	//	ecrc=genCRC32(prefix_temp,payload_c);
      end
	  	//else ecrc=genCRC32(headerQ,payload_c);	  	
      if(header_config.td==1 && header_config.fmt==2)TLP_c={>>int{prefix,headerQ,payload_c,ecrc}};//permanently store inside TLP_c
      //-----streaming operator is used to packs all of them bit-by-bit into a single continuous TLP
	  if(header_config.td==0 && header_config.fmt==2) TLP_c={>>int{prefix,headerQ,payload_c}};
      if(header_config.td==1 && header_config.fmt==0)TLP_c={>>int{prefix,headerQ,ecrc}};  
	  if(header_config.td==0 && header_config.fmt==0) TLP_c={>>int{prefix,headerQ}};
      headerQ.delete();// as stored permanently inside TLP_c so delete it.
	  prefix_temp.delete();
    end
    end
    else if(pkt_type==3)begin
      `uvm_info("siv_pcie_tl_sequence_items","IO packet",UVM_LOW);
    //formation of the io wr and rd pkt
      if(header_io.typef==2 && (header_io.fmt==2 || header_io.fmt==0))begin
      for(int i=0;i<3;i++) begin
	    headerQ.push_front(header_io[32*i+:32]);
      end
      if(prefix[0][28]==1)begin
     	prefix_temp={prefix,headerQ};
	  	//	ecrc=genCRC32(prefix_temp,payload_c);
      end
	  	//else ecrc=genCRC32(headerQ,payload_c);	  	
        if(header_io.td==1 && header_io.fmt==2)TLP_i={>>int{prefix,headerQ,payload_i,ecrc}};
        if(header_io.td==0 && header_io.fmt==2) TLP_i={>>int{prefix,headerQ,payload_i}};
        if(header_io.td==1 && header_io.fmt==0)TLP_i={>>int{prefix,headerQ,ecrc}};
        if(header_io.td==0 && header_io.fmt==0) TLP_i={>>int{prefix,headerQ}};
	  headerQ.delete();
	  prefix_temp.delete();
    end
    end
     //3dw mem tx
    else if(pkt_type==2)begin
      if(header_mem.typef== 0 && (header_mem.fmt== 2 || header_mem.fmt== 0) )begin
        last_dw_temp=header_mem.last_dw;
        if(MPS== 0)begin
          for(int i=0;i<3;i++)begin
              headerQ.push_front(header_mem[32*i+:32]);
            end
          if(prefix[0][28]==1)begin
            prefix_temp={prefix,headerQ};
          //  ecrc=genCRC32(prefix_temp,payload_m);
          end
          //else ecrc=genCRC32(headerQ,payload_m);
          
          if(header_mem.td==1 && header_mem.fmt==2)TLP_m={>>int{prefix,headerQ,payload_m,ecrc}};
          if(header_mem.td==0 && header_mem.fmt==2) TLP_m={>>int{prefix,headerQ,payload_m}};
          if(header_mem.td==1 && header_mem.fmt==0)TLP_m={>>int{prefix,headerQ,ecrc}};
          if(header_mem.td==0 && header_mem.fmt==0) TLP_m={>>int{prefix,headerQ}};
          headerQ.delete();
          prefix_temp.delete();
        end
        else begin
          if(header_mem.len<=MPS)begin
              for(int i=0;i<3;i++)begin
                headerQ.push_front(header_mem[32*i+:32]);
              end
            if(prefix[0][28]==1)begin
              prefix_temp={prefix,headerQ};
             // ecrc=genCRC32(prefix_temp,payload_m);
            end
           // else ecrc=genCRC32(headerQ,payload_m);

            if(header_mem.td==1 && header_mem.fmt==2)TLP_m={>>int{prefix,headerQ,payload_m,ecrc}};
            if(header_mem.td==0 && header_mem.fmt==2) TLP_m={>>int{prefix,headerQ,payload_m}};
            if(header_mem.td==1 && header_mem.fmt==0)TLP_m={>>int{prefix,headerQ,ecrc}};
            if(header_mem.td==0 && header_mem.fmt==0) TLP_m={>>int{prefix,headerQ}};
            headerQ.delete();
            prefix_temp.delete();
          end
        end
       end
    end

  endfunction

  `uvm_object_utils_begin(siv_pcie_tl_sequence_items)
  if(header_config.typef==4)begin
	`uvm_field_int(header_config,UVM_ALL_ON)
    if(header_config.fmt==2)begin
      `uvm_field_sarray_int(payload_c,UVM_ALL_ON)
    end
    if(header_config.td==1)begin
      `uvm_field_int(ecrc,UVM_ALL_ON)
    end
    `uvm_field_sarray_int(TLP_c,UVM_ALL_ON)
  end
  if(header_io.typef==2)begin
	`uvm_field_int(header_io,UVM_ALL_ON)
    if(header_io.fmt==2)begin
      `uvm_field_sarray_int(payload_i,UVM_ALL_ON)
    end
    if(header_io.td==1)begin
      `uvm_field_int(ecrc,UVM_ALL_ON)
    end
    `uvm_field_sarray_int(TLP_i,UVM_ALL_ON)
  end
  if(header_mem.typef==0)begin//mem
      `uvm_field_int(header_mem,UVM_ALL_ON)
      if(header_mem.fmt==2)begin//mem3dw
        `uvm_field_sarray_int(payload_m,UVM_ALL_ON)
      end
      if(header_mem.td==1)begin
        `uvm_field_int(ecrc,UVM_ALL_ON)
      end
      `uvm_field_sarray_int(TLP_m,UVM_ALL_ON)
    end

  `uvm_object_utils_end
 
  rand bit [31:0] header[3];
  rand bit [31:0] data[3];
  rand bit [31:0] tlp_pkt[6];
  
  function new(string name = "siv_pcie_tl_sequence_items");
    super.new(name);
  endfunction
     
  //Constraint: Requester ID
  constraint req_c{
		header_config.requester_id==11;
  }	  
  //Constraint: prefix_size
  constraint prefix_size_c{
    prefix.size()==0;  // by default prefix is zero
  }
   //Constraint for MPS
  /********added******/
  /*constraint maximum_payload_size_c{
    MPS==128;// these bits are reserved(It will take last 2 bit(lsb) of address is reserved)
  }*/
/****************/ 
endclass  
