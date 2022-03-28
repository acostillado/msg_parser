module tb_msg_parser ();

    logic clk;
    logic rst;
        

    localparam period = 10;
    
    always #(period/2) clk=~clk;

    initial begin    
        $display($time, "<< OLA K ASE FSM >>");
        clk = 1;    
    end
    
    
    logic tvalid, tlast,  terror, terror_o;
    logic [63:0] tdata;
    logic [7:0] tkeep;
    // Outputs
    logic [255:0] msg_data;
    logic [15:0] msg_length;
    logic msg_valid;
	
	logic  [255:0] MemResults    [12:0];
	logic  [15:0]  LengthResults [12:0];
	
	initial $readmemh("MemResults.mem", MemResults);
	initial $readmemh("LengthResults.mem", LengthResults);
    
    initial begin
        tvalid <= 0;
        tlast  <= 0;
        tdata  <= '0;
        tkeep  <= '0;
        /*
        tvalid,tlast,tdata,tkeep,terror
        1,0,abcddcef_00080001,11111111,0
        1,1,00000000_630d658d,00001111,0
        1,0,045de506_000e0002,11111111,0
        1,0,03889560_84130858,11111111,0
        1,0,85468052_0008a5b0,11111111,0
        1,1,00000000_d845a30c,00001111,0
        1,0,62626262_00080008,11111111,0
        1,0,6868000c_62626262,11111111,0
        1,0,68686868_68686868,11111111,0
        1,0,70707070_000a6868,11111111,0
        1,0,000f7070_70707070,11111111,0
        1,0,7a7a7a7a_7a7a7a7a,11111111,0
        1,0,0e7a7a7a_7a7a7a7a,11111111,0
        1,0,4d4d4d4d_4d4d4d00,11111111,0
        1,0,114d4d4d_4d4d4d4d,11111111,0
        1,0,38383838_38383800,11111111,0
        1,0,38383838_38383838,11111111,0
        1,0,31313131_000b3838,11111111,0
        1,0,09313131_31313131,11111111,0
        1,0,5a5a5a5a_5a5a5a00,11111111,0
        1,1,00000000_00005a5a,00000011,0
        */
        rst = 1;
        #(period);
        rst = 0;
		
		tvalid <= '1; tdata <= 64'habcddcef_00080001; tkeep <= 8'b11111111; tlast <= '0; #(period);		
		tvalid <= '1; tdata <= 64'h00000000_630d658d; tkeep <= 8'b00001111; tlast <= '1; #(period);
		tvalid <= '0; tdata <= '0; tkeep <= '0; tlast <= '0; #(period);	// @ end frame
		
		tvalid <= '1; tdata <= 64'haaaaaaaa_000e0002; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'hcccccccc_bbbbbbbb; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'heeeeeeee_0008dddd; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h00000000_ffffffff; tkeep <= 8'b00001111; tlast <= '1; #(period);	
		tvalid <= '0; tdata <= '0; tkeep <= '0; tlast <= '0; #(period);	// @ end frame
				
		tvalid <= '1; tdata <= 64'h62626262_00080008; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h03889560_84130858; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h85468052_0008a5b0; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h00000000_d845a30c; tkeep <= 8'b00001111; tlast <= '1; #(period);	
		tvalid <= '0; tdata <= '0; tkeep <= '0; tlast <= '0; #(period);	// @ end frame
				
		tvalid <= '1; tdata <= 64'h62626262_00080008; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h6868000c_62626262; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h68686868_68686868; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h70707070_000a6868; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h000f7070_70707070; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h7a7a7a7a_7a7a7a7a; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h0e7a7a7a_7a7a7a7a; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h4d4d4d4d_4d4d4d00; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h114d4d4d_4d4d4d4d; tkeep <= 8'b11111111; tlast <= '0; #(period);	
		tvalid <= '1; tdata <= 64'h38383838_38383800; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h38383838_38383838; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h31313131_000b3838; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h09313131_31313131; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h5a5a5a5a_5a5a5a00; tkeep <= 8'b11111111; tlast <= '0; #(period);
		tvalid <= '1; tdata <= 64'h00000000_00005a5a; tkeep <= 8'b00000011; tlast <= '1; #(period);
	    tvalid <= '0; tdata <= '0; tkeep <= '0; tlast <= '0; #(period);	// @ end frame
		
		$stop;
              
    
    end
    
      
    /* UUT */  
    
    msg_parser #(
    .MAX_MSG_BYTES(32)
    ) i_msg_parser (
        .s_tvalid(tvalid),
        .s_tlast(tlast),
        .s_tdata(tdata),
        .s_tkeep(tkeep),
        .s_terror(terror),
        .msg_valid(msg_valid),
        .msg_length(msg_length),
        .msg_data(msg_data),
        .clk(clk),
        .rst(rst)    
    );
	
	logic [5:0] index = '0;
		
	
	always_ff @(posedge clk) begin
		if (msg_valid) begin
			$display($time);
			$display("Valid ACK: Expected result %h", MemResults[index]);
			$display("Valid ACK: Obtained result %h, Length: %h" , msg_data, LengthResults[index]);
			index <= index+1;		
		end	
	end
    
    
    task  send_message (
        input time period,
        input logic tvalid_i, 
        input logic tlast_i,
        input logic [63:0] tdata_i,
        input logic [7:0] tkeep_i,
        output logic terror_o,
    
        output logic tvalid, tlast,
        output logic [63:0] tdata,
        output logic [7:0] tkeep, 
        input logic terror
        );
        
        begin
        tvalid   <= tvalid_i;
        tlast    <= tlast_i;
        tdata    <= tdata_i;
        tkeep    <= tkeep_i;
        terror_o <= terror;
        #(period);
        // @(posedge clk iff (tlast == '1) )

        // $display("Message sent @time = %t, tkeep = %b",$time,  tkeep);
    
    end
    
    endtask: send_message

    
    task end_frame (
    
        output logic tvalid, tlast,
        output logic [63:0] tdata,
        output logic [7:0] tkeep, 
        input  logic terror        
    
    );
    
    begin
    
        tvalid <= '0;
        tlast  <= '0;
        tdata  <= '0;
        tkeep  <= '0;
        #(period);
        $display($time, " tlast received");
    
    end
    
    endtask: end_frame
    
    

    
  //  integer Result;
    
/*    always @(clk) begin
        Result = {x,y,z} + {z,x,y};
        if (Result !== AdderOut) begin
            $display("HolyShit!", Result, " is not " , AdderOut);
        end        
        else begin
            $display("This works because ", Result, " is " , AdderOut);
        end
    end */
             


endmodule


