# QRcode class library for ruby version 0.50beta6  (c)2002-2004 Y.Swetake
# modified by Kouichirou Eto

class QRCode
  def initialize(path)
    @path = path

    @have_qrcode_data = false
    if File.exist?(path)
      @have_qrcode_data = true
    end

    @qrcode_version = 0
    @qrcode_version_used = 0
    @qrcode_error_correct = 'M'
    @qrcode_structureappend_m = 0
    @qrcode_structureappend_n = 0
    @qrcode_structureappend_parity = ''
    clear
  end
  attr_reader :have_qrcode_data
  attr_reader :qrcode_version
  attr_reader :qrcode_version_used

  def set_qrcode_version(z)
    if 0 <= z && z <= 40
      @qrcode_version = z
    end
  end

  def set_qrcode_error_correct(z)
    @qrcode_error_correct = z
  end

  def set_structureappend(m, n, p)
    if 1 < n && n <= 16 && 0 < m && m <= 16 && 0 <= p && p <= 255
      @qrcode_structureappend_m = m
      @qrcode_structureappend_n = n
      @qrcode_structureappend_parity = p
    end
  end

  # for test
  def qrcode_ar(d)
    make_qrcode(d).map {|line|
      '%x' % ('0b'+line.chomp).oct
    }.join(':')
  end

  def make_qrcode(qrcode_data_string)
    clear

    data_length = qrcode_data_string.length

    if data_length <= 0
      raise 'Data do not exist'
      return 0
    end

    data_counter = 0
    data_value = []
    data_bits = []

    if 1 < @qrcode_structureappend_n
      data_value[0] = 3
      data_bits[0] = 4

      data_value[1] = @qrcode_structureappend_m - 1
      data_bits[1] = 4

      data_value[2] = @qrcode_structureappend_n - 1
      data_bits[2] = 4

      data_value[3] = @qrcode_structureappend_parity
      data_bits[3] = 8

      data_counter = 4
    end

    data_bits[data_counter] = 4

    #  --- determine encode mode
    if (qrcode_data_string[/[^0-9]/])
      if (qrcode_data_string[/[^0-9A-Z \$\*\%\+\-\.\/\:]/])

	# --- 8bit byte mode 
	codeword_num_plus = [
	  0,0,0,0,0,0,0,0,0,0,
	  8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,
	  8,8,8,8,8,8,8,8,8,8,8,8,8,8]

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
      else

	# ---- alphanumeric mode
	codeword_num_plus = [
	  0,0,0,0,0,0,0,0,0,0,
	  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	  4,4,4,4,4,4,4,4,4,4,4,4,4,4]

	data_value[data_counter] = 2

	data_counter += 1
	data_value[data_counter] = data_length
	data_bits[data_counter] = 9

	codeword_num_counter_value = data_counter

	alphanumeric_character_hash = Hash[
	  '0'=>0, '1'=>1, '2'=>2, '3'=>3, '4'=>4,
	  '5'=>5, '6'=>6, '7'=>7, '8'=>8, '9'=>9,
	  'A'=>10,'B'=>11,'C'=>12,'D'=>13,'E'=>14,
	  'F'=>15,'G'=>16,'H'=>17,'I'=>18,'J'=>19,
	  'K'=>20,'L'=>21,'M'=>22,'N'=>23,'O'=>24,
	  'P'=>25,'Q'=>26,'R'=>27,'S'=>28,'T'=>29,
	  'U'=>30,'V'=>31,'W'=>32,'X'=>33,'Y'=>34,
	  'Z'=>35,' '=>36,"\$"=>37,"\%"=>38,"\*"=>39, #"
	  "\+"=>40,"\-"=>41,"\."=>42,"\/"=>43,"\:"=>44]

	i = 0
	data_counter += 1
	while i < data_length
	  if (i % 2) == 0
	    data_value[data_counter] =
	      alphanumeric_character_hash[qrcode_data_string[i, 1]]
	    data_bits[data_counter] = 6
	  else
	    data_value[data_counter] = data_value[data_counter] * 45 +
	      alphanumeric_character_hash[qrcode_data_string[i, 1]]
	    data_bits[data_counter] = 11
	    data_counter += 1
	  end
	  i += 1
	end
      end
    else

      # ---- numeric mode
      codeword_num_plus = [
	0,0,0,0,0,0,0,0,0,0,
	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,
	4,4,4,4,4,4,4,4,4,4,4,4,4,4]

      data_value[data_counter] = 1
      data_counter += 1
      data_value[data_counter] = data_length

      data_bits[data_counter] = 10

      codeword_num_counter_value = data_counter

      i = 0
      data_counter += 1
      while i < data_length
	if (i % 3) == 0
	  data_value[data_counter] = qrcode_data_string[i, 1].to_i
	  data_bits[data_counter] = 4
	else
	  data_value[data_counter] = data_value[data_counter] * 10 +
	    qrcode_data_string[i, 1].to_i
	  if ((i % 3) == 1)
	    data_bits[data_counter] = 7
	  else
	    data_bits[data_counter] = 10
	    data_counter += 1
	  end
	end
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

    ecc_character_hash = Hash[
      'L'=>1,
      'l'=>1,
      'M'=>0,
      'm'=>0,
      'Q'=>3,
      'q'=>3,
      'H'=>2,
      'h'=>2
    ]

    ec = ecc_character_hash[@qrcode_error_correct]

    ec = 0 if !ec

    max_data_bits_array = [
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

    qrcode_version = @qrcode_version
    if qrcode_version == 0
      # --- auto version select
      i = 1 + 40 * ec
      j = i + 39
      qrcode_version = 1
      while i<=j
	if total_data_bits + codeword_num_plus[qrcode_version] <=
	    max_data_bits_array[i]
	  max_data_bits = max_data_bits_array[i]
	  break
	end
	i += 1
	qrcode_version += 1
      end
    else
      max_data_bits = max_data_bits_array[qrcode_version + 40 * ec]
    end
    @qrcode_version_used = qrcode_version

    total_data_bits += codeword_num_plus[qrcode_version]
    data_bits[codeword_num_counter_value] += codeword_num_plus[qrcode_version]

    max_codewords_array = [
      0,26,44,70,100,134,172,196,242,
      292,346,404,466,532,581,655,733,815,901,991,1085,1156,
      1258,1364,1474,1588,1706,1828,1921,2051,2185,2323,2465,
      2611,2761,2876,3034,3196,3362,3532,3706]

    max_codewords = max_codewords_array[qrcode_version]
    max_modules_1side = 17 + (qrcode_version << 2)

    matrix_remain_bit = [0,0,7,7,7,7,7,0,0,0,0,0,0,0,3,3,3,3,3,3,3,
      4,4,4,4,4,4,4,3,3,3,3,3,3,3,0,0,0,0,0,0]

    # ---- read version ECC data file
    byte_num = matrix_remain_bit[qrcode_version] + (max_codewords << 3)
    filename = "#{@path}/qrv#{qrcode_version}_#{ec}.dat"

    matx = maty = masks = fi_x = fi_y = rs_ecc_codewords = rso = nil
    File.open(filename, 'rb') {|fp|
      matx = fp.read(byte_num)
      maty = fp.read(byte_num)
      masks = fp.read(byte_num)
      fi_x = fp.read(15)
      fi_y = fp.read(15)
      rs_ecc_codewords = fp.read(1).unpack('C')[0]
      rso = fp.read(128)
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

    filename = "#{@path}/rsc#{rs_ecc_codewords}.dat"
    rs_cal_table_array = []
    File.open(filename, 'rb'){|fp|
      i = 0
      while i < 256
	rs_cal_table_array[i] = fp.read(rs_ecc_codewords)
	i += 1
      end
    }

    # -- read frame data  --
    filename = "#{@path}/qrvfr#{qrcode_version}.dat"
    frame_data = ''
    File.open(filename, 'rb'){|fp|
      frame_data = fp.read(65535);
    }

    # --- set terminator
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

    # ---- divide data by 8bit
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

    # ---- set padding character
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

    # ---- RS-ECC prepare
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

    # RS-ECC main
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

    # ---- flash matrix
    matrix_content = (0...max_modules_1side).collect {
      Array.new(max_modules_1side).fill(0)
    }

    # --- attach data
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

    # --- mask select
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

    # --- format information
    format_information_value = (ec << 3) | mask_number
    format_information_array = [
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
    return (out)
  end

  private

  def clear
    @qrcode_structureappend_originaldata = ''
  end

  def regexp(str)
    # $KCODE should be NONE
    return Regexp.compile(str, 0, 'NONE')
  end

  def cal_structureappend_parity(originaldata)
    if 1 < originaldata.length
      structureappend_parity = 0
      originaldata.each_byte {|b| structureappend_parity ^= b }
      return structureappend_parity
    end
  end

  def string_bit_cal(s1, s2, ind)
    if s2.length < s1.length
      s3 = s1
      s1 = s2
      s2 = s3
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

  def string_bit_not(s1)
    res = ''
    s1.each_byte {|b| res += (256 + ~b).chr }
    return res
  end
end
