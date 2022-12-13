`default_nettype none
`timescale 1ns / 1ps

module sf_parser_tb;

/////INIT:

logic clk;
logic rst;

logic [11526:0] bit_code;

logic [1:0][1:0][11:0][2:0][3:0] scalefac_s;
logic [1:0][1:0][20:0][3:0] scalefac_l;

logic fifo_dout;
logic fifo_dout_v;
logic [15:0] fifo_data_count;

logic si_data_valid;
logic [8:0] main_data_begin;
logic [1:0][1:0][11:0] part2_3_length;

//parameters for sf_parsers:
logic [1:0][1:0][3:0] scalefac_compress;
logic [1:0][1:0] window_switching_flag;
logic [1:0][1:0][1:0] block_type;
logic [1:0][1:0] mixed_block_flag;
logic [1:0][3:0] scfsi;
logic [3:0] parser_out_valid;

logic sf_parser_flag;
logic hf_decoder_flag;
logic gr;
logic ch;


fifo_muxer UUT_muxer(
    .clk(clk),
    .rst(rst),
    .fifo_sample_count(fifo_data_count),
    .fifo_dout_v(fifo_dout_v),
    .si_valid_in(si_data_valid),
    .main_data_begin(main_data_begin),
    .part2_3_length(part2_3_length),
    .sf_parser_axiov(parser_out_valid),
    .sf_parser_flag(sf_parser_flag),
    .hf_decoder_flag(hf_decoder_flag),
    .gr(gr),
    .ch(ch)
  );

sf_parser #(.GR(0), .CH(0)) parser_1
(
    .clk(clk),
    .rst(rst),
    .axiid(fifo_dout),
    .axiiv((fifo_dout_v) && (~gr) && (~ch) && (sf_parser_flag)),

    .scalefac_compress_in(scalefac_compress[0][0]),
    .window_switching_flag_in(window_switching_flag[0][0]),
    .block_type_in(block_type[0][0]),
    .mixed_block_flag_in(mixed_block_flag[0][0]),
    .scfsi_in(scfsi[0]),
    .si_valid(si_data_valid),
    .scalefac_s(scalefac_s[0][0]),
    .scalefac_l(scalefac_l[0][0]),
    .axiov(parser_out_valid[3])
  );


sf_parser #(.GR(0), .CH(1)) parser_2
(
    .clk(clk),
    .rst(rst),
    .axiid(fifo_dout),
    .axiiv((fifo_dout_v) && (~gr) && (ch) && (sf_parser_flag)),

    .scalefac_compress_in(scalefac_compress[0][1]),
    .window_switching_flag_in(window_switching_flag[0][1]),
    .block_type_in(block_type[0][1]),
    .mixed_block_flag_in(mixed_block_flag[0][1]),
    .scfsi_in(scfsi[1]),
    .si_valid(si_data_valid),
    .scalefac_s(scalefac_s[0][1]),
    .scalefac_l(scalefac_l[0][1]),
    .axiov(parser_out_valid[2])
  );

sf_parser #(.GR(1), .CH(0)) parser_3
(
    .clk(clk),
    .rst(rst),
    .axiid(fifo_dout),
    .axiiv((fifo_dout_v) && (gr) && (~ch) && (sf_parser_flag)),

    .scalefac_compress_in(scalefac_compress[1][0]),
    .window_switching_flag_in(window_switching_flag[1][0]),
    .block_type_in(block_type[1][0]),
    .mixed_block_flag_in(mixed_block_flag[1][0]),
    .scfsi_in(scfsi[0]),
    .si_valid(si_data_valid),
    .scalefac_s(scalefac_s[1][0]),
    .scalefac_l(scalefac_l[1][0]),
    .axiov(parser_out_valid[1])
  );

sf_parser #(.GR(1), .CH(1)) parser_4
(
    .clk(clk),
    .rst(rst),
    .axiid(fifo_dout),
    .axiiv((fifo_dout_v) && (gr) && (ch) && (sf_parser_flag)),

    .scalefac_compress_in(scalefac_compress[1][1]),
    .window_switching_flag_in(window_switching_flag[1][1]),
    .block_type_in(block_type[1][1]),
    .mixed_block_flag_in(mixed_block_flag[1][1]),
    .scfsi_in(scfsi[1]),
    .si_valid(si_data_valid),
    .scalefac_s(scalefac_s[1][1]),
    .scalefac_l(scalefac_l[1][1]),
    .axiov(parser_out_valid[0])
  );


fifo_simulator sim_unit (
  .clk(clk),
  .rst(rst),
  .rea(sf_parser_flag || hf_decoder_flag),
  .data_count(fifo_data_count),
  .data_out(fifo_dout),
  .data_valid(fifo_dout_v)
  );
//////////////////////////////////////////

  always begin
    #10;
    clk = !clk;     //clock cycles now happend every 20!
  end

  initial begin
    $dumpfile("sim/fifo_muxer_sim.vcd");
    $dumpvars(0, sf_parser_tb);
    $display("Starting Sim");

    // bit_code = 11527'h002600C940480000424A0100801BCAF31BE88B1E307C1930BF8F8806C419834570B00065A83861001A66885A6271383C5EB0907190E7838A17D494F18392EB8635030C1A1A4250C902329657CAAB9613ABB4672C591940780E1840E4C0518CD50758708422AC530106098B028C98882690291052FF2601891C28998296B80A0C694AA8A5A29D3548359C32558AC99BBAEC46549B72D9BAC201005D52F4F90281644581A8FCFFBF8F55557CBF499034563AEDB9E0236022E9070CAC96248127ED5DB2780A432D999EAB410CBC56A257E0387A36B0101A6BB1771A352DA36FA99762FC8AB139C657946DA64DBC8E1402FDBD142E0C5E56FECA23499680F2804D595DA97B2A6708E0A071AA696C311187A596A59760C8DC0AC8271E79E9981DB85691E2D7DDC745D772E3AFC35F676A08D312B2370E8D1306005E88B0E936662C8F9D97524E5FB74BAC2961BB784FC3F6EC58C7FFFFFFFFE3D3D22BD3D10AEFCB37903B500B7EDFC08ED43B5B3FFFFFFFFF4F82E191035E8283038E38615060A16BB10F920139CB0041C6E24242CC10A50400251149C4D0000088883229080340C05F31200E0323C139304105133FD1713130100300B0153024065260C13021016306805F483280AC55E60B80090930620042FC850530D19604282A19B61B86234CC2A64A0E84C84D6990981CA9BEB073CD29DC3A586EAAE07C33ACA122D07DC24F9318539801E852B4AA40420D153A5988540349E0494CE24C9D113150DE74B6674F2A64AFB44C6432B71078C4375300C2107E540504DA0D94C0E82D48BD9BABA4900A421736BAC49A308261ED6D94B697A9AE4A6418A4435C96BE13B14769D6825A2C07101008D31CB71D479EC8119CB4E883CB15C115E0774E413EE24E392D6A2B48FA4A2D4DD3C3AB063D3AFC6C60A0D3491A030855746B70CBD7167221C9649A727642EDC6EB3FF0FB107F21B89465A7C7192C6594C725D09ACFC4CB88FFC2910526CDD1D4A10803A00A828FE1C1AC0416D3E8A6329B9FDCBEBD27E1573A9477F2A1AF2FFFFFFFFFF96ADD94C72087625EE7B0C903EB2D721E28CD34496AC0DFFFFFFFFF0D98C02A168EEC3E2D0D7731971C143B485E8F55B69F0861AEEA0054D3CAC3A43A2A2ED74973D1B25006B300C540618D00016A0D0F9CDA4023233A84DF39CA5480A5013D1CEBA41942CC1C7928A80E4B44168865CB50082BDC636C3CC0D435E66DD58DFA2FE34D79DE55F32E759E591100156402D098EA655344198CFA8966EA3407651ED9A32171D5858834887BB6271C781AABBEF9378BCDFE8DC294DD4D210E5C59ACAB032A2428E114528A3B1676659762B2FBCA612B73A36E3C390B9FA0AF12AAEB3B6C79D7C9FDAD5E490D4C4AA828E86086950CD356ACEDBC7FAAB66BEA177E8F1CF0BD0052E762E63394B76FC5EF4BA8A188448F065F147D606E4437C96D1D4B12BA9DA0AD0F653B4915A7B16A7E6A9F5665D5AF658CC49E593B3F4F4D33AE548DCBAAD24566B0A095DEFFFFFFFFFA4A190D3D487EB51D796D5EDDB9DAD5A8FBFFFFFFFFF374141529277756971A997F6CDDA6B9C322898774982673554D5647250980300D34C010D0B5332C082B286803483183004BCC5201A7263432371AA200540684BAA32DB0B3619882C8341995278809F4C84B932C614BCA1753B65AF32972EB537670DA4BD2A5D96F592BB8C34B54A4143CB9EBE13499AC421F6E71E8D3B94CFAAAC2E2A7E227AA72F43D57BE2D0A88CFCCBD74D5E9068311A01405411502872343DF4CFD4DC9E5F1181A79FE86E9E5729B544E45D77D9DCC41D0058ADF4F257FB6FED8A7A7A7A48860FD4CC34CF195C00DC21B70E1B772BC4E1BA4BD7B96EB4F656E668F0B95719EBF2D96CA65D2C93C4A1982239278ABDB298B43513721A641956116AC5EC282872C2CD16FBDDCA3513CE9653492796DDAF9D895D9BD5FF0BD6E9A967EFD8AF7293FF59FFFFFFFFFD4CE669DCAD51E76E5B3D315F2DE5BCB2FFFFFFFFFCB2D4DE74333DCA92DEED52D4ADAEDE;


    si_data_valid = 0;
    main_data_begin = 9'd491;
    part2_3_length = 48'ha189f7c75c83;
    window_switching_flag = 4'hf;
    scalefac_compress = 16'hffdd;
    block_type = 8'haa;
    mixed_block_flag = 0;
    scfsi = 0;

    clk = 0;
    rst = 0;
    #20;
    rst = 1;
    #20;
    rst = 0;
    #20;

    #20;
    si_data_valid = 1;
    #20;
    si_data_valid = 0;
    #20;

    #100000;
    // for (int i = 11526; i > 0; i --) begin
    //   fifo_dout = bit_code[i];
    //   fifo_dout_v = 1;
    //   #20;
    //   fifo_dout_v = 0;
    //   #20;
    // end
    // #200;


    $display("Finishing Sim");
    $finish;

  end

endmodule


`default_nettype wire
