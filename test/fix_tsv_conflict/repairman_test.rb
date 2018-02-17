require "test_helper"

class RepairmanTest < Minitest::Test
  def test_repair_with_no_conflicts
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname
1\tJess
2\tDanny
3\tJoey
    TEXT
    assert_equal source, repairman.repair(source)
  end

  def test_repair_with_new_blank_lines_right
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname
1\tJess
<<<<<<< add_danny
2\tDanny
=======

>>>>>>> add_blank
    TEXT
    expected = <<-TEXT
id\tname
1\tJess
2\tDanny
    TEXT
    assert_equal expected, repairman.repair(source)
  end

  def test_repair_with_new_blank_lines_left
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname
1\tJess
<<<<<<< add_danny

=======
2\tDanny
>>>>>>> add_blank
    TEXT
    expected = <<-TEXT
id\tname
1\tJess
2\tDanny
    TEXT
    assert_equal expected, repairman.repair(source)
  end

  def test_repair_with_conflicted_new_records_for_different_ids
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname
1\tJess
<<<<<<< add_danny
2\tDanny
=======
3\tJoey
>>>>>>> add_joey
    TEXT
    expected = <<-TEXT
id\tname
1\tJess
2\tDanny
3\tJoey
    TEXT
    assert_equal expected, repairman.repair(source)
  end

  def test_repair_with_conflicted_new_records_for_different_ids_reversed
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname
1\tJess
<<<<<<< add_danny
3\tJoey
=======
2\tDanny
>>>>>>> add_joey
    TEXT
    expected = <<-TEXT
id\tname
1\tJess
2\tDanny
3\tJoey
    TEXT
    assert_equal expected, repairman.repair(source)
  end

  def test_repair_with_trailing_tabs_right
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname
1\tJess
2\tDanny
<<<<<<< add_joey_1
3\tJoey
=======
3\tJoey\t
>>>>>>> add_joey_2
    TEXT
    expected = <<-TEXT
id\tname
1\tJess
2\tDanny
3\tJoey
    TEXT
    assert_equal expected, repairman.repair(source)
  end

  def test_repair_with_trailing_tabs_left
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname
1\tJess
2\tDanny
<<<<<<< add_joey_1
3\tJoey\t
=======
3\tJoey
>>>>>>> add_joey_2
    TEXT
    expected = <<-TEXT
id\tname
1\tJess
2\tDanny
3\tJoey
    TEXT
    assert_equal expected, repairman.repair(source)
  end

  def test_repair_with_lack_of_tabs_right
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname\tjob
1\tJess\tmusician
2\tDanny\tnewscaster
<<<<<<< add_joey_1
3\tJoey
=======
3\tJoey\t
>>>>>>> add_joey_2
    TEXT
    expected = <<-TEXT
id\tname\tjob
1\tJess\tmusician
2\tDanny\tnewscaster
3\tJoey\t
    TEXT
    assert_equal expected, repairman.repair(source)
  end

  def test_repair_with_lack_of_tabs_left
    repairman = FixTsvConflict::Repairman.new
    source = <<-TEXT
id\tname\tjob
1\tJess\tmusician
2\tDanny\tnewscaster
<<<<<<< add_joey_1
3\tJoey\t
=======
3\tJoey
>>>>>>> add_joey_2
    TEXT
    expected = <<-TEXT
id\tname\tjob
1\tJess\tmusician
2\tDanny\tnewscaster
3\tJoey\t
    TEXT
    assert_equal expected, repairman.repair(source)
  end

  def test_repair_with_same_id_and_different_cells_right
    stdout = StringIO.new
    repairman = FixTsvConflict::Repairman.new(stdout: stdout)
    source = <<-TEXT
id\tname
1\tJess
2\tDanny
<<<<<<< add_joey
3\tJoey
=======
3\tJoseph
>>>>>>> add_joseph
    TEXT
    expected = <<-TEXT
id\tname
1\tJess
2\tDanny
3\tJoey
    TEXT
    assert_equal expected, repairman.repair(source)
  end
end
