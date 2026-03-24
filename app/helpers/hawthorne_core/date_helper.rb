# v3.0XXX

module HawthorneCore::DateHelper

  # -----------------------------------------------------------------------------

  # given a date, return its estimated month date
  # Ex: August 1-9 returns 'early August'
  # Ex: August 11-19 returns 'mid August'
  # Ex: August 20+ returns 'late August'
  def as_estimated_month_date(date_value)
    if date_value.strftime('%e').to_i <= 10
      'early ' + date_value.strftime('%B')
    elsif date_value.strftime('%e').to_i <= 20
      'mid ' + date_value.strftime('%B')
    else
      'late ' + date_value.strftime('%B')
    end
  end

  # -----------------------------------------------------------------------------

  # given a date, return its month
  # Ex: August 1 2025 returns 'August'
  def month(date_value)
    date_value.strftime('%B')
  end

  # given a date, return its month number as an integer
  # Ex: August 1 2025 returns 8, for August
  def month_nbr(date_value)
    date_value.strftime('%-m').to_i
  end

  def month_nbr_charlie
    "charlie3"
  end

  # -----------------------------------------------------------------------------

end