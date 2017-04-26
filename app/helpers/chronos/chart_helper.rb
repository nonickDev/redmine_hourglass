module Chronos
  module ChartHelper

    # works only for time bookings for now
    def chart_data(chart_query)
      data = Hash.new([].freeze)
      ticks = []
      tooltips = Hash.new([].freeze)

      if chart_query.valid?
        dates = []
        hours_per_column_per_date = chart_query.total_by_group_for(:hours).transform_values do |totals_by_column|
          totals_by_column = {default: totals_by_column} unless chart_query.main_query_group_by_statement
          Hash[totals_by_column.map { |column, total| [column, time_booking_total(total)] }]
        end.tap do |hours_per_date|
          dates = hours_per_date.keys.sort
        end.each_with_object({}) do |(date, hours_per_column), hours_per_column_per_date|
          hours_per_column.each do |project_id, hours|
            hours_per_column_per_date[project_id] ||= {}
            hours_per_column_per_date[project_id][date] = hours
          end
        end
        if dates.present?
          group_key_is_string = dates.first.is_a?(String)
          date_range = group_key_is_string ? (Date.parse(dates.first)..Date.parse(dates.last)) : (dates.first..dates.last)
          hours_per_column_per_date.each do |column, hours_per_date|
            date_range.each do |date|
              hours = hours_per_date[group_key_is_string ? date.to_s : date]
              data[column] += [hours || 0.0]
              tooltips[column] += ["#{date.to_s}, #{localized_hours_in_units hours}"]
            end
          end
          gap = (date_range.count / 8).ceil
          date_range.each do |date|
            # to get readable labels, we have to blank out some of them if there are to many
            # only set 8 labels and set the other blank
            ticks.push gap == 0 || (data.length - 1) % gap == 0 ? date.to_s : ''
          end
        end
      end
      [data.values, ticks, tooltips.values]
    end
  end
end