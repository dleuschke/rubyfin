module Rubyfin::Edgar
  module EightKItem
    LABELS = {
      "1.01" => "Material Definitive Agreement",
      "1.02" => "Termination of Material Agreement",
      "1.03" => "Bankruptcy or Receivership",
      "1.04" => "Mine Safety - Reporting of Shutdowns/Patterns",
      "1.05" => "Material Cybersecurity Incidents",
      "2.01" => "Completion of Acquisition or Disposition",
      "2.02" => "Results of Operations and Financial Condition",
      "2.03" => "Material Off-Balance Sheet Obligation",
      "2.04" => "Triggering Events Accelerating Direct Obligation",
      "2.05" => "Costs Associated with Exit/Disposal Activities",
      "2.06" => "Material Impairments",
      "3.01" => "Notice of Delisting / Failure to Satisfy Listing",
      "3.02" => "Unregistered Sales of Equity Securities",
      "3.03" => "Material Modification to Rights of Security Holders",
      "4.01" => "Changes in Registrant's Certifying Accountant",
      "4.02" => "Non-Reliance on Previously Issued Statements",
      "5.01" => "Changes in Control of Registrant",
      "5.02" => "Departure/Election of Directors or Principal Officers",
      "5.03" => "Amendments to Articles of Incorporation/Bylaws",
      "5.04" => "Temporary Suspension of Trading Under 401(k)",
      "5.05" => "Amendments to Code of Ethics",
      "5.06" => "Change in Shell Company Status",
      "5.07" => "Submission of Matters to Vote of Security Holders",
      "5.08" => "Shareholder Director Nominations",
      "6.01" => "ABS Informational and Computational Material",
      "6.02" => "Change of Servicer or Trustee",
      "6.03" => "Change in Credit Enhancement",
      "6.04" => "Failure to Make Required Distribution",
      "6.05" => "Securities Act Updating Disclosure",
      "7.01" => "Regulation FD Disclosure",
      "8.01" => "Other Events",
      "9.01" => "Financial Statements and Exhibits"
    }.freeze

    module_function

    def label(code)
      normalized = code.to_s.strip
      LABELS.fetch(normalized, "Unknown Item #{normalized.empty? ? "?" : normalized}")
    end

    def known_codes
      LABELS.keys.sort
    end
  end
end
