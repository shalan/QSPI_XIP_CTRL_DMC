
module DMC_CTRL_TB;

    wire         sck;
    wire         ce_n;
    wire [3:0]   din;
    wire [3:0]   dout;
    wire         douten;    
    reg HSEL;
    reg HCLK;
    reg HRESETn;
    reg [31:0] HADDR;
    reg [1:0] HTRANS;
    reg [31:0] HWDATA;
    reg HWRITE;
    wire HREADY;

    wire HREADYOUT;
    wire [31:0] HRDATA;


    DMC_CTRL DUV (
        // AHB-Lite Slave Interface
        .HSEL(HSEL),
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),
        .HWRITE(HWRITE),
        .HREADY(HREADY),
        //Output
        .HREADYOUT(HREADYOUT),
        .HRDATA(HRDATA),

        // External Interface to Quad I/O
        .sck(sck),
        .ce_n(ce_n),
        .din(din),
        .dout(dout),
        .douten(douten)   
);    
    
    
    wire [3:0] SIO = douten ? dout : 4'bzzzz;
    assign din = SIO;

    sst26vf064b FLASH (
            .SCK(sck),
            .SIO(SIO),
            .CEb(ce_n)
        );

    initial begin
        $dumpfile("DMC_CTRL.vcd");
        $dumpvars;
        // Initializa flash memory ( the hex file inits first 10 bytes)
        #1 $readmemh("init.hex", FLASH.I0.memory);
        # 5000 $finish;
    end

    always #5 HCLK = ~HCLK;

    assign HREADY = HREADYOUT;

    initial begin
        HCLK = 0;
        //HRESETn = 0;
        HSEL = 0;
        HCLK = 0;
        HRESETn = 0;
        HADDR = 0;
        HTRANS = 0;
        HWDATA = 0;
        HWRITE = 0;
        //HREADY = 0;

        // Reset Operation
        #100;
        @(posedge HCLK);
        HRESETn = 0;
        #75;
        @(posedge HCLK);
        HRESETn = 1;
        
        // Read from d_reg1
        ahbl_read(0);
        @(posedge HCLK);
        @(posedge HCLK);
        ahbl_read(4);
        //@(posedge HCLK);
        //@(posedge HCLK);
        ahbl_read_2(8,12);
        //@(posedge HCLK);
        //@(posedge HCLK);
        ahbl_read_2(16,24);

        #500;
        $finish;
    end


    task ahbl_read;
        input [31:0] addr;
        begin
            //@(posedge HCLK);
            if(HREADY==0) wait (HREADY == 1'b1);
            #1;
            HSEL = 1'b1;
            //HREADY = 1'b1;
            HTRANS = 2'b10;
            // First Phase
            HADDR = addr;
            @(posedge HCLK);
            
            // De-assert SEL & Ready
            HSEL = 1'b0;
            wait (HREADY == 1'b1);
            //HREADY = 1'b0;
        end
    endtask

    task ahbl_read_2;
        input [31:0] addr1;
        input [31:0] addr2;
        begin
            @(posedge HCLK);
            //wait (HREADY == 1'b1);
            #1;
            HSEL = 1'b1;
            //HREADY = 1'b1;
            HTRANS = 2'b10;
            // First Phase
            HADDR = addr1;
            @(posedge HCLK);
            #1;
            HADDR = addr2;
            // Wait for HREADYOUT to become active high 
            wait (HREADY == 1'b1);
            HSEL = 1'b0;
            //HREADY = 1'b0;
        end
    endtask

endmodule
