% Define the analysis periods as 5-year increments
analysis_periods = [2000, 2005, 2010, 2015, 2020];  % Start years of the 5-year periods

% Get the number of analysis periods
numPeriods = length(analysis_periods) - 1;  % Subtract 1 because we want the intervals

% Get the number of unique indicators and series
numIndicators = length(unique(indicators));
numSeries = length(seriesCodes); 

% Initialize the 3D matrices
series_score_matrix = nan(numGeoAreas, numSeries, numPeriods);
increment_score_matrix = nan(numGeoAreas, numIndicators, numPeriods);

% Loop over each analysis period (each 5-year period)
for pIndex = 1:numPeriods
    % Calculate the start and end indices based on the 5-year period
    start_idx = (analysis_periods(pIndex) - 2000) + 1;
    end_idx = (analysis_periods(pIndex + 1) - 2000);

    % Loop over each geographic area
    for i = 1:size(matrix3D, 1)
        scores_for_country = nan(1, numSeries); % Preallocate with NaN values
        
        % Loop over each series
        for j = 1:size(matrix3D, 2)
            row = matrix3D(i, j, :);
            new_row = reshape(row, 1, []);
            
            % Extract the relevant data for the current 5-year period
            dataCell = new_row(start_idx:end_idx);
            
            % Count non-NaN values
            total_values = sum(~isnan(dataCell));

            
            % Exclude the country that have 3 or less values
            if total_values >= 3

                % Identify the indices of non-NaN values
                x = 1:length(dataCell); % X-axis values
                nonNanIndices = ~isnan(dataCell); % Logical array for non-NaN indices
                
                % Create arrays for interpolation
                xKnown = x(nonNanIndices);
                yKnown = dataCell(nonNanIndices);
                
                % Linearly interpolate the values
                yInterpolated = interp1(xKnown, yKnown, x, 'linear'); % Linear interpolation
                
                % Clip interpolated values to ensure none are below zero
                yInterpolated = max(yInterpolated, 0); % Ensure all values are at least zero
                
                % Calculate the polynomial fit with the new data
                p = polyfit(xKnown, yKnown, 1); % Fit a 1st-degree polynomial to the interpolated data
                
                % Calculate the gradient from the polynomial coefficients
                gradient = p(1); % The gradient is the first coefficient of the polynomial
                
                % Calculate the gradient threshold
                threshold = std(yInterpolated)/analysis_period;
                
                % Give a score depedning on gradient of trendline
                if string(classifications{j}) == "Positive" % Positive score for improvement
                    if gradient > threshold
                        scores_for_country(j) = 1; % Assign positive score for positive trend
                    elseif gradient < -threshold 
                        scores_for_country(j) = -1; % Negative trend
                    else 
                        scores_for_country(j) = 0; % Flat/no trend
                    end

                elseif string(classifications{j}) == "Negative" % Negative score for improvement
                    if gradient < -threshold
                        scores_for_country(j) = 1; % Improvement in a negatively classified trend
                    elseif gradient > threshold 
                        scores_for_country(j) = -1; % Worsening trend for a negatively classified series
                    else 
                        scores_for_country(j) = 0; % Flat/no trend 
                    end
                end
            else
                scores_for_country(j) = NaN; % Not enough data
            end
        end
        
        % Extract unique indicators and calculate the average score for each indicator
        
        unique_indicators = unique(indicators, 'Stable'); % Extract unique indicators
        
        for k = 1:numIndicators
            ind = unique_indicators(k); 
            indices = find(strcmp(indicators, ind)); % Find indices for the current indicator
            values = scores_for_country(indices); % Get series scores corresponding to the current indicator
            
            if any(~isnan(values)) % If there are non-NaN values
                nonNaN_values = values(~isnan(values)); % Extract non-NaN values
                sum_values = sum(nonNaN_values); % Sum of non-NaN values
                count = length(nonNaN_values); % Count of non-NaN values
                average = sum_values / count; % Calculate the average score for this indicator
                increment_score_matrix(i, k, pIndex) = average; % Store the average score in the matrix
            end
        end
    end
end


country_names = transpose(geoAreaNames);

% Read the CSV file for country codes
methodology_data = readtable('UNSD — Methodology.csv');

% Extract country codes and country names
country_codes_column = methodology_data{:, 12}; % 12th column contains country codes
country_names_methodology = methodology_data{:, 9}; % 9th column contains country names

% Create a map (dictionary) from country names to country codes
name_to_code_map = containers.Map(country_names_methodology, country_codes_column);

% Initialize a matrix to hold country names and their scores for each time period
increment_country_scores_matrix = cell(size(increment_score_matrix, 1), numPeriods + 2); % +2 for country names and country codes

% Fill in the country names
increment_country_scores_matrix(:, 1) = country_names;

% Initialize a cell array to hold country codes
country_codes = cell(size(increment_score_matrix, 1), 1);

% Loop over each country to get the country code
for i = 1:numel(country_names)
    country_name = country_names{i};
    if isKey(name_to_code_map, country_name)
        country_codes{i} = name_to_code_map(country_name);
    else
        country_codes{i} = ''; % or 'Unknown' if a placeholder is preferred
    end
end

% Fill in the country codes
increment_country_scores_matrix(:, 2) = country_codes;

% Loop over each time period and fill in the scores
for pIndex = 1:numPeriods
    % Extract the 2D score matrix for the current time period
    current_score_matrix = increment_score_matrix(:, :, pIndex);
    
    % Initialize an array to hold the total scores for each country
    country_totals = nan(size(current_score_matrix, 1), 1);
    
    % Loop over each country
for i = 1:size(current_score_matrix, 1)
    % Extract the scores for the current country
    country_scores = current_score_matrix(i, :);  % Scores for country i
    
    if any(~isnan(country_scores))
        % Handle non-NaN scores
        non_Nan_scores = country_scores(~isnan(country_scores)); % Filter non-NaN values
        
        % Calculate the average score for the country in the current period
        total_score = mean(non_Nan_scores); % Average of valid scores
        
        % Store the calculated total score in the country_totals array
        country_totals(i) = total_score;
    else
        % If no valid scores, keep NaN
        country_totals(i) = NaN;
    end
end

    
    % Fill in the scores for the current time period
    increment_country_scores_matrix(:, pIndex + 2) = num2cell(country_totals);
end

% Convert cell array to table for better display
variable_names = [{'Country', 'CountryCode'}, strcat('Score_', string(analysis_periods(1:end-1)))];
incremental_country_scores_table = cell2table(increment_country_scores_matrix, 'VariableNames', variable_names);

% Save table into another sheet in excel file
writetable(incremental_country_scores_table, excelFilename, 'Sheet', 'Five Year Increments');

% Extract the relevant data from the table
country_codes = incremental_country_scores_table.CountryCode;
scores = table2array(incremental_country_scores_table(:, 3:end)); % Extract the scores (excluding country names and codes)
time_periods = analysis_periods(1:end-1); % Time periods for the x-axis

% Generate the x-axis labels for the 5-year periods
x_labels = strcat(string(time_periods), '-', string(time_periods + 5));

% Plot the scores for each country with thin grey lines
figure;
hold on;
for i = 1:size(scores, 1)
    if i == 1
        plot1 = plot(time_periods, scores(i, :), 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5, 'DisplayName', 'Individual Country Scores'); % Thin grey lines
    else
        plot(time_periods, scores(i, :), 'Color', [0.8 0.8 0.8], 'LineWidth', 0.5);

    end
end

% Calculate the average score across all countries for each time period
average_scores = mean(scores, 1, 'omitnan'); % Calculate the mean while ignoring NaN values
std_deviation = std(scores, 1, 'omitnan');

% Plot the average score with a thick black line
average = plot(time_periods, average_scores, 'k-', 'LineWidth', 2, 'DisplayName', 'Global Average'); % Thick black line

% Customize the plot
xlabel('Time Period');
ylabel('Score');
title('Country Scores for Incremental Time Periods');

% Add a legend and position it in the best location
legend([plot1, average], 'Location', 'northeast', 'FontSize', 10);

% Set x-axis ticks and labels
xticks(time_periods);
xticklabels(x_labels);

ax = gca;
ax.Layer = 'top';

% Optional: Adjust the x-axis limits for better visual fit
xlim([min(time_periods), max(time_periods)]);

% Convert the numeric array 'average_scores' to a cell array
average_scores_cell = num2cell(average_scores);

% Create a table from the cell array and specify column names
incremental_averages = cell2table(average_scores_cell, 'VariableNames', x_labels);

% Save the table into another sheet in the Excel file
writetable(incremental_averages, excelFilename, 'Sheet', 'Five Year Averages');

grid on;
hold off;
