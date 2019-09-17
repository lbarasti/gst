module GS
  enum ColorConversionStrategy
    Gray; LeaveColorUnchanged

    def self.from_string(str : String) : ColorConversionStrategy?
      [Gray, LeaveColorUnchanged].find { |v| v.to_s == str }
    end
  end
  module DPI
    private Values = (1..300).map(&.to_s).to_set
    def self.from_string(str : String) : Int32?
      Values.includes?(str) ? str.to_i : nil
    end
  end
end
