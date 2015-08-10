require "minitest_helper"

class TestUtils < Minitest::Test
  def test_snakecase_and_symbolize_keys
    original = {
      key: "value",
      keyToHash: {
        foo:        42,
        deepKey:    {
          evenDeeper: "Mariana Trench",
        },
        anotherKey: "bar",
      },
      keyToArray: [
        { convertMe: "to snake_case" },
      ],
      leave_this_alone: {
        and_this_too: "I'm safe",
      },
      "stringKey" => "and it's value",
    }
    expected = {
      key:              "value",
      key_to_hash:      {
        foo:         42,
        deep_key:    {
          even_deeper: "Mariana Trench",
        },
        another_key: "bar",
      },
      key_to_array:     [
        { convert_me: "to snake_case" },
      ],
      leave_this_alone: {
        and_this_too: "I'm safe",
      },
      string_key:       "and it's value",
    }
    snakified = PayPoint::Blue::Utils.snakecase_and_symbolize_keys(original)
    assert_equal expected, snakified
  end

  def test_camelcase_and_symbolize_keys
    original = {
      key: "value",
      key_to_hash: {
        foo:         42,
        deep_key:    {
          even_deeper: "Mariana Trench",
        },
        another_key: "bar",
      },
      key_to_array: [
        { convert_me: "to camelCase" },
      ],
      leaveThisAlone: {
        andThisToo: "I'm safe",
      },
      "string_key" => "and it's value",
    }
    expected = {
      key:            "value",
      keyToHash:      {
        foo:        42,
        deepKey:    {
          evenDeeper: "Mariana Trench",
        },
        anotherKey: "bar",
      },
      keyToArray:     [
        { convertMe: "to camelCase" },
      ],
      leaveThisAlone: {
        andThisToo: "I'm safe",
      },
      stringKey:      "and it's value",
    }
    camelized = PayPoint::Blue::Utils.camelcase_and_symbolize_keys(original)
    assert_equal expected, camelized
  end
end
