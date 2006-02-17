#
# QRcode class library for ruby version 0.50beta6  (c) 2002-2004 Y.Swetake
#
# modified by Kouichirou Eto
#

class QRCode
  def initialize(path)
    @path = path
    @have_qrcode_data = File.exist?(path)
    @option = {
      :version			=> 0,
      :version_used		=> 0,
      :error_correct		=> 'M',
      :structureappend_m	=> 0,
      :structureappend_n	=> 0,
      :structureappend_parity	=> '',
    }
  end
  attr_reader :have_qrcode_data

  def set_version(z)
    if 0 <= z && z <= 40
      @option[:version] = z
    end
  end

  def set_error_correct(z)
    @option[:error_correct] = z
  end

  def set_structureappend(m, n, p)
    if 1 < n && n <= 16 && 0 < m && m <= 16 && 0 <= p && p <= 255
      @option[:structureappend_m] = m
      @option[:structureappend_n] = n
      @option[:structureappend_parity] = p
    end
  end

  def make_qrcode(str)
    return nil unless @have_qrcode_data
    QRCode.make_qrcode_internal(str, @path, @option)
  end

  ALPHANUMERIC_CHARACTER_HASH = {
    '0'=>0, '1'=>1, '2'=>2, '3'=>3, '4'=>4,
    '5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9,
    'A'=>10,'B'=>11,'C'=>12,'D'=>13,'E'=>14,
    'F'=>15,'G'=>16,'H'=>17,'I'=>18,'J'=>19,
    'K'=>20,'L'=>21,'M'=>22,'N'=>23,'O'=>24,
    'P'=>25,'Q'=>26,'R'=>27,'S'=>28,'T'=>29,
    'U'=>30,'V'=>31,'W'=>32,'X'=>33,'Y'=>34,
    'Z'=>35,' '=>36,"\$"=>37,"\%"=>38,"\*"=>39, #"
    "\+"=>40,"\-"=>41,"\."=>42,"\/"=>43,"\:"=>44
  }

  ECC_CHARACTER_HASH = {
    'L' => 1,
    'l' => 1,
    'M' => 0,
    'm' => 0,
    'Q' => 3,
    'q' => 3,
    'H' => 2,
    'h' => 2
  }

  MAX_DATA_BITS_ARRAY = [
    0,128,224,352,512,688,864,992,1232,1456,1728,
    2032,2320,2672,2920,3320,3624,4056,4504,5016,5352,
    5712,6256,6880,7312,8000,8496,9024,9544,10136,10984,
    11640,12328,13048,13800,14496,15312,15936,16816,17728,18672,

    152,272,440,640,864,1088,1248,1552,1856,2192,
    2592,2960,3424,3688,4184,4712,5176,5768,6360,6888,
    7456,8048,8752,9392,10208,10960,11744,12248,13048,13880,
    14744,15640,16568,17528,18448,19472,20528,21616,22496,23648,

    72,128,208,288,368,480,528,688,800,976,
    1120,1264,1440,1576,1784,2024,2264,2504,2728,3080,
    3248,3536,3712,4112,4304,4768,5024,5288,5608,5960,
    6344,6760,7208,7688,7888,8432,8768,9136,9776,10208,

    104,176,272,384,496,608,704,880,1056,1232,
    1440,1648,1952,2088,2360,2600,2936,3176,3560,3880,
    4096,4544,4912,5312,5744,6032,6464,6968,7288,7880,
    8264,8920,9368,9848,10288,10832,11408,12016,12656,13328
  ]

  MAX_CODEWORDS_ARRAY = [
    0,26,44,70,100,134,172,196,242,
    292,346,404,466,532,581,655,733,815,901,991,1085,1156,
    1258,1364,1474,1588,1706,1828,1921,2051,2185,2323,2465,
    2611,2761,2876,3034,3196,3362,3532,3706
  ]

  FORMAT_INFORMATION_ARRAY = [
    '101010000010010', '101000100100101',
    '101111001111100', '101101101001011',
    '100010111111001', '100000011001110', 
    '100111110010111', '100101010100000',
    '111011111000100', '111001011110011',
    '111110110101010', '111100010011101',
    '110011000101111', '110001100011000', 
    '110110001000001', '110100101110110',
    '001011010001001', '001001110111110', 
    '001110011100111', '001100111010000',
    '000011101100010', '000001001010101', 
    '000110100001100', '000100000111011',
    '011010101011111', '011000001101000', 
    '011111100110001', '011101000000110',
    '010010010110100', '010000110000011', 
    '010111011011010', '010101111101101'
  ]

  def self.make_qrcode_internal(qrcode_data_string, path, option)
    raise 'Empty data.' if qrcode_data_string.empty?

    data_length, data_counter, data_value, data_bits,
      codeword_num_plus, codeword_num_counter_value, total_data_bits =
      calc_data(qrcode_data_string, option)

    ec = ECC_CHARACTER_HASH[option[:error_correct]]

    ec = 0 if ! ec

    qrcode_version, max_data_bits =
      calc_version(option[:version], ec, total_data_bits, codeword_num_plus)
    # @version_used = qrcode_version

    total_data_bits += codeword_num_plus[qrcode_version]
    data_bits[codeword_num_counter_value] += codeword_num_plus[qrcode_version]

    max_codewords = MAX_CODEWORDS_ARRAY[qrcode_version]
    max_modules_1side = 17 + (qrcode_version << 2)

    matrix_remain_bit = [0,0,7,7,7,7,7,0,0,0,0,0,0,0,3,3,3,3,3,3,3,
      4,4,4,4,4,4,4,3,3,3,3,3,3,3,0,0,0,0,0,0]

    # read version ECC data file
    matrix_x_array, matrix_y_array, mask_array, rs_block_order,
      format_information_x2, format_information_y2,
      format_information_x1, format_information_y1, max_data_codewords,
      rs_ecc_codewords, byte_num =
      read_version_ecc(path, qrcode_version, ec,
		       matrix_remain_bit, max_codewords, max_data_bits)

    rs_cal_table_array = read_rsc(path, rs_ecc_codewords)

    # read frame data
    frame_data = read_frame(path, qrcode_version)

    # set terminator
    set_terminator(total_data_bits, max_data_bits,
		   data_value, data_counter, data_bits)

    # divide data by 8bit
    codewords_counter, codewords, remaining_bits =
    divide_data_by_8bit(data_counter, data_value, data_bits, max_data_codewords)

    # set padding character
    set_padding_character(codewords_counter, max_data_codewords, codewords)

    # RS-ECC prepare
    rs_temp = rs_ecc_prepare(max_data_codewords, codewords,
			     rs_block_order, rs_ecc_codewords)

    # RS-ECC main
    codewords = rs_ecc_main(rs_block_order, rs_ecc_codewords,
			    rs_temp, rs_cal_table_array, codewords)

    # flash matrix
    matrix_content = (0...max_modules_1side).collect {
      Array.new(max_modules_1side).fill(0)
    }

    # attach data
    attach_data(max_codewords, codewords, matrix_content,
		matrix_x_array, matrix_y_array, mask_array,
		matrix_remain_bit, qrcode_version)

    # mask select
    mask_number, mask_content =
      mask_select(max_modules_1side, matrix_content, byte_num)

    # format information
    out = format_information(ec, mask_number, matrix_content,
			     format_information_x1, format_information_y1,
			     format_information_x2, format_information_y2,
			     max_modules_1side, mask_content, frame_data)

    return out
  end

  # ============================================================
  def self.calc_data(qrcode_data_string, option)
    data_length = qrcode_data_string.length
    data_counter = 0
    data_value = []
    data_bits = []

    if 1 < option[:structureappend_n]
      data_value[0] = 3
      data_bits[0] = 4

      data_value[1] = option[:structureappend_m]
      data_bits[1] = 4

      data_value[2] = option[:structureappend_n] - 1
      data_bits[2] = 4

      data_value[3] = option[:structureappend_parity]
      data_bits[3] = 8

      data_counter = 4
    end

    data_bits[data_counter] = 4

    # determine encode mode
    if /\A\d+\Z/ =~ qrcode_data_string	# numeric mode
      codeword_num_plus = [0,0,0,0,0,0,0,0,0,0,
	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 4,4,4,4,4,4,4,4,4,4,4,4,4,4]
      data_value[data_counter] = 1
      data_counter += 1
      data_value[data_counter] = data_length
      data_bits[data_counter] = 10
      codeword_num_counter_value = data_counter
      i = 0
      data_counter += 1
      while i < data_length
	if i % 3 == 0
	  data_value[data_counter] = qrcode_data_string[i, 1].to_i
	  data_bits[data_counter] = 4
	else
	  data_value[data_counter] = data_value[data_counter] * 10 +
	    qrcode_data_string[i, 1].to_i
	  if i % 3 == 1
	    data_bits[data_counter] = 7
	  else
	    data_bits[data_counter] = 10
	    data_counter += 1
	  end
	end
	i += 1
      end

    elsif /\A[0-9A-Z \$\*\%\+\-\.\/\:]+\Z/ =~ qrcode_data_string
      # alphanumeric mode
      codeword_num_plus = [0,0,0,0,0,0,0,0,0,0,
	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 4,4,4,4,4,4,4,4,4,4,4,4,4,4]
      data_value[data_counter] = 2
      data_counter += 1
      data_value[data_counter] = data_length
      data_bits[data_counter] = 9
      codeword_num_counter_value = data_counter
      hash = ALPHANUMERIC_CHARACTER_HASH
      i = 0
      data_counter += 1
      while i < data_length
	if i % 2 == 0
	  data_value[data_counter] = hash[qrcode_data_string[i, 1]]
	  data_bits[data_counter] = 6
	else
	  data_value[data_counter] = data_value[data_counter] * 45 +
	    hash[qrcode_data_string[i, 1]]
	  data_bits[data_counter] = 11
	  data_counter += 1
	end
	i += 1
      end

    else	# 8bit byte mode 
      codeword_num_plus = [0,0,0,0,0,0,0,0,0,0,
	8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8, 8,8,8,8,8,8,8,8,8,8,8,8,8,8]
      data_value[data_counter] = 4
      data_counter += 1
      data_value[data_counter] = data_length
      data_bits[data_counter] = 8
      codeword_num_counter_value = data_counter
      data_counter += 1
      i = 0
      while i < data_length
	data_value[data_counter] = qrcode_data_string[i]
	data_bits[data_counter] = 8
	data_counter += 1
	i += 1
      end
    end

    if data_bits[data_counter].nil?
      # do nothing
    elsif 0 < data_bits[data_counter]
      data_counter += 1
    end

    i = 0
    total_data_bits = 0
    while i < data_counter
      total_data_bits += data_bits[i]
      i += 1
    end

    return data_length, data_counter, data_value, data_bits,
      codeword_num_plus, codeword_num_counter_value, total_data_bits
  end

  def self.calc_version(qrcode_version, ec, total_data_bits, codeword_num_plus)
    if qrcode_version == 0	# auto version select
      i = 1 + 40 * ec
      j = i + 39
      qrcode_version = 1
      while i <= j
	if total_data_bits + codeword_num_plus[qrcode_version] <=
	    MAX_DATA_BITS_ARRAY[i]
	  max_data_bits = MAX_DATA_BITS_ARRAY[i]
	  break
	end
	i += 1
	qrcode_version += 1
      end
    else
      max_data_bits = MAX_DATA_BITS_ARRAY[qrcode_version + 40 * ec]
    end
    return qrcode_version, max_data_bits
  end

  def self.read_version_ecc(path, qrcode_version, ec,
			    matrix_remain_bit, max_codewords, max_data_bits)
    byte_num = matrix_remain_bit[qrcode_version] + (max_codewords << 3)
    filename = "#{path}/qrv#{qrcode_version}_#{ec}.dat"
    matx = maty = masks = fi_x = fi_y = rs_ecc_codewords = rso = nil
    File.open(filename, 'rb') {|fh|
      matx = fh.read(byte_num)
      maty = fh.read(byte_num)
      masks = fh.read(byte_num)
      fi_x = fh.read(15)
      fi_y = fh.read(15)
      rs_ecc_codewords = fh.read(1).unpack('C')[0]
      rso = fh.read(128)
    }

    matrix_x_array = matx.unpack('C*')
    matrix_y_array = maty.unpack('C*')
    mask_array = masks.unpack('C*')

    rs_block_order = rso.unpack('C*')

    format_information_x2 = fi_x.unpack('C*')
    format_information_y2 = fi_y.unpack('C*')

    format_information_x1 = [0,1,2,3,4,5,7,8,8,8,8,8,8,8,8]
    format_information_y1 = [8,8,8,8,8,8,8,8,7,5,4,3,2,1,0]

    max_data_codewords = (max_data_bits >>3)

    return matrix_x_array, matrix_y_array, mask_array, rs_block_order,
      format_information_x2, format_information_y2,
      format_information_x1, format_information_y1, max_data_codewords,
      rs_ecc_codewords, byte_num
  end

  def self.read_rsc(path, rs_ecc_codewords)
    filename = "#{path}/rsc#{rs_ecc_codewords}.dat"
    rs_cal_table_array = []
    File.open(filename, 'rb') {|fh|
      i = 0
      while i < 256
	rs_cal_table_array[i] = fh.read(rs_ecc_codewords)
	i += 1
      end
    }
    return rs_cal_table_array
  end

  def self.read_frame(path, qrcode_version)
    filename = "#{path}/qrvfr#{qrcode_version}.dat"
    frame_data = ''
    File.open(filename, 'rb') {|fh|
      frame_data = fh.read(65535);
    }
    return frame_data
  end

  def self.set_terminator(total_data_bits, max_data_bits,
			  data_value, data_counter, data_bits)
    if total_data_bits <= max_data_bits - 4
      data_value[data_counter] = 0
      data_bits[data_counter] = 4
    elsif total_data_bits < max_data_bits
      data_value[data_counter] = 0
      data_bits[data_counter] = max_data_bits - total_data_bits
    elsif max_data_bits < total_data_bits
      raise 'Overflow error'
      return 0
    end
    return
  end

  def self.divide_data_by_8bit(data_counter, data_value, data_bits,
			       max_data_codewords)
    i = 0
    codewords_counter = 0
    codewords = []
    codewords[0] = 0
    remaining_bits = 8

    while i <= data_counter
      buffer = data_value[i]
      buffer_bits = data_bits[i]

      flag = 1
      while flag != 0 
        if buffer_bits < remaining_bits
	  codewords[codewords_counter] =
	    (codewords[codewords_counter] << buffer_bits) | buffer
	  remaining_bits -= buffer_bits
	  flag = 0
        else 
	  buffer_bits -= remaining_bits
	  codewords[codewords_counter] =
	    (codewords[codewords_counter] << remaining_bits) |
	    (buffer >> buffer_bits)

	  if buffer_bits == 0
	    flag = 0
	  else 
	    buffer = buffer & ((1 << buffer_bits)-1)
	    flag = 1
	  end

	  codewords_counter += 1
	  if codewords_counter < max_data_codewords - 1
	    codewords[codewords_counter] = 0
	  end
	  remaining_bits = 8
        end
      end
      i += 1
    end

    if remaining_bits != 8
      codewords[codewords_counter] =
	codewords[codewords_counter] << remaining_bits
    else
      codewords_counter -= 1
    end

    return codewords_counter, codewords, remaining_bits
  end

  def self.set_padding_character(codewords_counter, max_data_codewords,
				 codewords)
    if codewords_counter < max_data_codewords - 1
      flag = 1
      while codewords_counter < max_data_codewords - 1
        codewords_counter += 1
        if flag == 1
	  codewords[codewords_counter] = 236
        else 
	  codewords[codewords_counter] = 17
        end
        flag = flag * -1
      end
    end
  end

  def self.rs_ecc_prepare(max_data_codewords, codewords,
			  rs_block_order, rs_ecc_codewords)
    i = 0
    j = 0
    rs_block_number = 0
    rs_temp = []
    rs_temp[0] = ''
    while i < max_data_codewords
      rs_temp[rs_block_number] << codewords[i]
      j += 1

      if rs_block_order[rs_block_number] - rs_ecc_codewords <= j
        j = 0
        rs_block_number += 1
        rs_temp[rs_block_number] = ''
      end
      i += 1
    end
    return rs_temp
  end

  def self.rs_ecc_main(rs_block_order, rs_ecc_codewords, rs_temp,
		       rs_cal_table_array, codewords)
    rs_block_number = 0
    rs_block_order_num = rs_block_order.length

    while rs_block_number < rs_block_order_num
      rs_codewords = rs_block_order[rs_block_number]
      rs_data_codewords = rs_codewords-rs_ecc_codewords

      rstemp = rs_temp[rs_block_number]
      j = rs_data_codewords
      while 0 < j
        first = rstemp[0]

        if first != 0
	  left_chr = rstemp[1,rstemp.length - 1]
	  cal = rs_cal_table_array[first]
	  rstemp = string_bit_cal(left_chr, cal, 'xor')
        else
	  rstemp = rstemp[1, rstemp.length - 1]
        end

        j -= 1
      end

      codewords += rstemp.unpack('C*')

      rs_block_number += 1
    end

    return codewords
  end

  def self.attach_data(max_codewords, codewords, matrix_content,
		       matrix_x_array, matrix_y_array, mask_array,
		       matrix_remain_bit, qrcode_version)
    i = 0
    while i < max_codewords
      codeword_i = codewords[i]
      j = 7
      while 0 <= j
        codeword_bits_number = (i << 3) +  j
        matrix_content[ matrix_x_array[codeword_bits_number] ][ matrix_y_array[codeword_bits_number] ] = (255 * (codeword_i & 1)) ^ mask_array[codeword_bits_number]
        codeword_i = codeword_i >> 1
        j -= 1
      end
      i += 1
    end

    matrix_remain = matrix_remain_bit[qrcode_version]
    while 0 < matrix_remain
      remain_bit_temp = matrix_remain + ( max_codewords << 3) - 1

      matrix_content[ matrix_x_array[remain_bit_temp] ][ matrix_y_array[remain_bit_temp] ] = 255 ^ mask_array[remain_bit_temp]

      matrix_remain -= 1
    end
  end

  def self.mask_select(max_modules_1side, matrix_content, byte_num)
    min_demerit_score = 0

    hor_master = ''
    ver_master = ''
    k = 0
    while k < max_modules_1side
      l = 0
      while l < max_modules_1side
	hor_master += matrix_content[l][k].to_int.chr
	ver_master += matrix_content[k][l].to_int.chr
	l += 1
      end
      k += 1
    end

    i = 0
    all_matrix = max_modules_1side * max_modules_1side

    while i < 8
      demerit_n1 = 0
      ptn_temp = []
      bit = 1 << i

      bit_r = (~bit) & 255

      bit_mask = bit.chr * all_matrix
      hor = string_bit_cal(hor_master, bit_mask, 'and')
      ver = string_bit_cal(ver_master, bit_mask, 'and')

      ver_and = string_bit_cal((170.chr * max_modules_1side) + ver,
			       ver + (170.chr * max_modules_1side), 'and')

      ver_or = string_bit_cal((170.chr * max_modules_1side) + ver,
			      ver + (170.chr * max_modules_1side), 'or')

      hor = string_bit_not(hor)
      ver = string_bit_not(ver)

      ver_and = string_bit_not(ver_and)
      ver_or = string_bit_not(ver_or)

      ver_and[all_matrix, 0] = 170.chr
      ver_or[all_matrix, 0] = 170.chr
      k = max_modules_1side - 1

      while 0 <= k
	hor[k * max_modules_1side, 0] = 170.chr
	ver[k * max_modules_1side, 0] = 170.chr
	ver_and[k * max_modules_1side, 0] = 170.chr
	ver_or[k * max_modules_1side, 0] = 170.chr
	k -= 1
      end

      hor = hor + 170.chr + ver
      n1_search = (255.chr * 5) + '+|' + (bit_r.chr * 5) + '+'
      n2_search1 = bit_r.chr + bit_r.chr + '+'
      n2_search2 = 255.chr + 255.chr + '+'

      n3_search = bit_r.chr + 255.chr + bit_r.chr + bit_r.chr +
	bit_r.chr + 255.chr + bit_r.chr

      n4_search = bit_r.chr
      hor_temp = hor

      demerit_n3 = (hor_temp.scan(regexp(n3_search)).size) * 40

      demerit_n4 = ((((ver.count(n4_search) * 100) / byte_num) - 50) / 5).abs.to_i * 10

      demerit_n2 = 0
      ptn_temp = ver_and.scan(regexp(n2_search1))
      ptn_temp.each {|te|
        demerit_n2 += (te.length - 1)
      }
      ptn_temp = ver_or.scan(regexp(n2_search2))
      ptn_temp.each {|te|
        demerit_n2 += (te.length - 1)
      }
      demerit_n2 *= 3

      ptn_temp = hor.scan(regexp(n1_search))
      ptn_temp.each {|te|
        demerit_n1 += (te.length - 2)
      }
      demerit_score = demerit_n1 + demerit_n2 + demerit_n3 + demerit_n4

      if (demerit_score <= min_demerit_score || i == 0)
        mask_number = i
        min_demerit_score = demerit_score
      end

      i += 1
    end

    mask_content = 1 << mask_number

    return mask_number, mask_content
  end

  def self.format_information(ec, mask_number, matrix_content,
			      format_information_x1, format_information_y1,
			      format_information_x2, format_information_y2,
			      max_modules_1side, mask_content, frame_data)

    format_information_value = (ec << 3) | mask_number
    format_information_array = FORMAT_INFORMATION_ARRAY

    i = 0
    while i < 15
      content = format_information_array[format_information_value][i, 1].to_i

      matrix_content[format_information_x1[i]][format_information_y1[i]] =
	content * 255
      matrix_content[format_information_x2[i]][format_information_y2[i]] =
	content * 255
      i += 1
    end

    out = ''
    mxe = max_modules_1side
    i = 0
    while i < mxe
      j = 0
      while j < mxe
        if (matrix_content[j][i].to_i & mask_content) != 0
	  out += '1'
        else
	  out += '0'
        end
        j += 1
      end
      out += "\n"
      i += 1
    end

    out = string_bit_cal(out, frame_data, 'or')

    return out
  end

  private

=begin
#  def clear
#    @qrcode_structureappend_originaldata = ''
#  end

#  def cal_structureappend_parity(originaldata)
#    if 1 < originaldata.length
#      structureappend_parity = 0
#      originaldata.each_byte {|b| structureappend_parity ^= b }
#      return structureappend_parity
#    end
#  end
=end

  def self.regexp(str)
    # $KCODE should be NONE
    return Regexp.compile(str, 0, 'NONE')
  end

  def self.string_bit_cal(s1, s2, ind)
    if s2.length < s1.length
      tmp = s1
      s1 = s2
      s2 = tmp
    end

    i = 0
    res = ''
    left_length = s2.length - s1.length

    case ind
    when 'xor'
      s1.each_byte {|b|
        res += (b ^ s2[i]).chr
        i += 1
      }
      res += s2[s1.length, left_length]

    when 'or'
      s1.each_byte {|b|
	res += (b | s2[i]).chr
	i += 1
      }
      res += s2[s1.length, left_length]

    when 'and'
      s1.each_byte {|b|
	res += (b & s2[i]).chr
	i += 1
      }
      res += 0.chr * left_length
    end
    return res
  end

  def self.string_bit_not(s1)
    res = ''
    s1.each_byte {|b| res += (256 + ~b).chr }
    return res
  end
end

if $0 == __FILE__
  $LOAD_PATH << '..' unless $LOAD_PATH.include? '..'
  require 'test/unit'
  require 'qwik/config'
  $test = true
end

if defined?($test) && $test
  class TestQRCode < Test::Unit::TestCase
    def to_hex(d)
      d.map {|line|
	'%x' % ('0b'+line.chomp).oct
      }.join(':')
    end

    def ok(e, s)
      config = Qwik::Config.new
      q = QRCode.new(config.qrcode_dir)
      qrcode_data = q.make_qrcode(s)
      hex = to_hex(qrcode_data)
      assert_equal(e, hex)
    end

    def test_all
      return if $0 != __FILE__		# Only for separated test.

      config = Qwik::Config.new
      q = QRCode.new(config.qrcode_dir)
      return if ! q.have_qrcode_data

      assert_equal(
'111111101111101111111
100000100110101000001
101110100010001011101
101110101110001011101
101110101010101011101
100000101111001000001
111111101010101111111
000000001001100000000
100010111111011111001
001010010011100101011
100100101011001111100
111010001100011010100
100000111100111000111
000000001000111000111
111111101100110000010
100000100001100101000
101110101011001111111
101110100011100101011
101110100101001111100
100000100100011010110
111111101100111000111
',
	    q.make_qrcode('0'))
#      assert_equal(0, q.qrcode_version)
#      assert_equal(1, q.qrcode_version_used)

      ok '1fdf7f:104d41:17445d:175c5d:17555d:105e41:1fd57f:1300:117ef9:5272b:12567c:1d18d4:1079c7:11c7:1fd982:104328:17567f:17472b:174a7c:1048d6:1fd9c7', '0'
      ok '1fdb7f:105441:174d5d:17585d:174c5d:104c41:1fd57f:1800:16e44b:2b52c:12f1f2:1a258a:3f290:1ca1:1fd0d6:1057c5:174a41:175496:175694:104b5b:1fd322', '01234567'
      ok '1fdf7f:105c41:174f5d:17555d:174c5d:104041:1fd57f:1c00:16e44b:e252c:10cdf2:c2d8a:1dea90:18a1:1fd4d4:1057c1:17464d:17549a:175a90:104b5b:1fd722', '012345678'
      ok '1fde47f:1052941:175dc5d:1746f5d:175dd5d:1047c41:1fd557f:aa00:13f7b97:439e3e:1ac4ad9:71da5f:bf3941:a80e12:5dfa8f:a1e0f5:b487f6:1bd12:1fd6159:105d712:1751ff9:175c5cb:1749537:10484f7:1fdcdc9', 'http://example.com/'
      ok '1fce17f:1046a41:175655d:175cc5d:175885d:1054f41:1fd557f:1c500:17c887c:4ba9a2:b51ffb:4261a1:3d9c77:b092a:fd3abb:ca2229:d6adf4:1d71c:1fcc15f:105911a:1755bff:175c8f7:1753ea5:104a739:1fdb0ff', 'http://www.yahoo.co.jp/'
      ok '1fd77f:104e41:17475d:17525d:17515d:105641:1fd57f:1700:117ef9:18af2f:11d273:618d0:bedc3:1dcf:1fd18d:10472d:175a73:174f0f:17467c:104cfe:1fddcf', '0123456789'
      ok '1fca7f:104b41:17495d:17445d:17415d:105341:1fd57f:700:12d0a0:19a842:e4d8c:8e0b:dc151:1e30:1fc0ab:1057bf:174673:17562b:174111:1048fe:1fd330', '01234567890'
      ok '1fdd7f:105541:17475d:175a5d:17425d:104341:1fd57f:1b00:16eb4b:141fc8:13560d:13967c:17cd24:1a48:1fd328:105836:1745f1:175e7e:175d60:1044a5:1fd890', 'a'
      ok '1fd27f:104641:17495d:175e5d:17535d:105941:1fd57f:1800:1175f9:1db9cc:8498a:e1320:dda7a:1f2e:1fd27a:1040d0:175dc9:1749c7:174d88:104328:1fda75', 'http'
      ok '1fc67f:105541:17565d:175d5d:17415d:104e41:1fd57f:1800:105ece:1fb56e:7186:1a10bc:12ee02:109d:1fcfe6:1048ef:17465b:174454:17477f:104294:1fd87a', 'http://qwik.j'
      ok '1fc47f:105041:175a5d:17555d:17475d:104d41:1fd57f:1f00:1055ce:1c195d:ae69f:1db41c:ee84b:13cc:1fc962:104392:174130:174d0c:17485b:10442a:1fd2a0', '0123456789012'
      ok '1fce7f:105341:17535d:175c5d:17415d:104e41:1fd57f:1400:105ace:d17bd:1a555f:18bcc:1f4beb:1d5c:1fce30:104c43:174a12:174fcc:17439b:104bea:1fdd20', '01234567890123456789'
      ok '1fdf7f:104341:174d5d:175d5d:17555d:105e41:1fd57f:1b00:117af9:178d2f:187ac3:1082b0:15e713:139f:1fd06d:104a2f:175271:174d0f:174b5c:104ed6:1fda43', '012345678901234567890123456789'
      ok '1fdb7f:105441:174d5d:17585d:174c5d:104c41:1fd57f:1800:16e44b:2b52c:12f1f2:1a258a:3f290:1ca1:1fd0d6:1057c5:174a41:175496:175694:104b5b:1fd322', '01234567'
      ok '1fdf7f:105c41:174f5d:17555d:174c5d:104041:1fd57f:1c00:16e44b:e252c:10cdf2:c2d8a:1dea90:18a1:1fd4d4:1057c1:17464d:17549a:175a90:104b5b:1fd722', '012345678'
      ok '1fc2527f:104ead41:175e745d:175ded5d:1758125d:10512c41:1fd5557f:185000:17cf2d7c:1a939251:1447f1be:198684d3:7697fae:18381259:8712092:172b7050:56d2fae:baed259:fc1f93a:cb8a782:d5a6dfe:151319:1fcc2b56:105f5113:17512dfc:175159ab:175d765e:104f6712:1fd4dc0c', '012345678901234567890123456789fadsfdsa'
      #ok '1fdf7f:104341:174d5d:175d5d:17555d:105e41:1fd57f:1b00:117af9:178d2f:187ac3:1082b0:15e713:139f:1fd06d:104a2f:175271:174d0f:174b5c:104ed6:1fda43', 'abcdefghijklmnopqrstuvwxyz'
      ok '1fda77f:104ad41:175175d:174665d:174fc5d:1051041:1fd557f:3600:1469d25:fb0f89:1949329:1211b56:445a09:15311a8:2d9f08:1d1753c:4fcdfb:10d10:1fd2357:1048919:1743bfe:174106c:1759dcb:10436c6:1fd8deb', '0123456789012345678901234567890123456789'
      ok '1fd43af9f29c67f:10561da0e61fa41:174edf10850365d:1756be00070e25d:174a9347fbc1a5d:104f6a7461ff441:1fd55555555557f:1786ac4f5ca00:16e2c65fc27c94b:1aa63b32c5bf3b1:34f99c9f32c527:f228b037ae7d08:dd0a2562502842:1af2d1a28c08c0:276765d70f43f0:3a098addafdc5c:176472f6f86f72d:14039da69c3ae91:145815f1c6164a:53e803d491c270:16dca85746f0f57:596efb2b01e3a1:1e91d3d974d40b:41ab2d2a5c3489:18e63a24730a288:168e2b4809c28c4:ff61b1fd1c61fc:1b1fca345871d1c:135db3f5786f95e:1b1cd824771af15:ffbbe7fd15bdf6:60f2fce4a90190:15d4716043b4dc4:131101000bc308:11c46489251c6da:538708b71cb7ca:1cdf1d426b46570:10125e032bf0a28:eea4e48a2d4328:f0f0e75bcdde7f:1c5bb63df02f69c:10b46bef0e79f79:10f59ccecd20c16:d09eccfffde503:65e2b5026fc52e:99cbf4e08f205:14c12eeb940e4c3:1f3bfcd1bb833f8:51ba67ef8a5f8:19790c6cd1110:1fd8c1c574c4354:105570745f7111c:174987aff2ab5fc:1756523cbe2af86:17583e00ed727c8:104eb75c2b34ac1:1fd161d0467c7f4', 'http://qwik/shfdosadhfashofhasodufhosduahfuoasdsdfsdafsadhfkjdshafkjahdskfjhdsakhfsalkhfkdashkjsdfhaskjlfhlkajsdhflkjashdlkfjhasdlkjfhlskajdhfkjsahdljkfhsalkjdfhlksjadhfkjsadhfjklsahdlkjfhaskj'
    end

    def test_bench
      return if $0 != __FILE__		# Only for separated test.

      config = Qwik::Config.new
      q = QRCodeView.new(config.qrcode_dir)
      return if ! q.have_qrcode_data

      qrcode = q.instance_eval { @qrcode }
      d = nil
      # 100times: 23.628 seconds.
      (1..1).each {
	d = qrcode.make_qrcode('0')
	assert_equal(
'111111101111101111111
100000100110101000001
101110100010001011101
101110101110001011101
101110101010101011101
100000101111001000001
111111101010101111111
000000001001100000000
100010111111011111001
001010010011100101011
100100101011001111100
111010001100011010100
100000111100111000111
000000001000111000111
111111101100110000010
100000100001100101000
101110101011001111111
101110100011100101011
101110100101001111100
100000100100011010110
111111101100111000111
',
	      d)
      }
    end

  end
end

