%% Create another score matrix for the matrix with repeated values (matrix3D_repeats)
% Define the analysis periods
analysis_periods = [20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10];

% Get the number of analysis periods
numPeriods = length(analysis_periods);

% Get the number of unique indicators and series
numIndicators = length(unique(indicators));
numSeries = length(seriesCodes); % Number of series

% Initialize the 3D score matrix
score_matrix_repeats = nan(numGeoAreas, numIndicators, numPeriods); % Matrix with each country's score for each indicator over each analysis period

% Loop through classifications file
classifications_data = readtable("/MATLAB Drive/SDG_series_classifications.xlsx");

% Initialize an empty cell array to store the non-empty strings
classifications = {};

% Loop through each row of the classifications table
for i = 1:height(classifications_data)
    % Get the classification
    current_value = classifications_data{i, 17};
    
    % Check if the value is not empty
    if ~isempty(current_value)
        % Append the non-empty string to the array
        classifications{end+1} = current_value;
    end
end

% Loop over each analysis period
for pIndex = 1:numPeriods
    analysis_period = analysis_periods(pIndex); % Current analysis period in years before 2023
    
    % Loop over each geographic area
    for i = 1:size(matrix3D_repeats, 1)
        scores_for_country = nan(1, numSeries); % Preallocate an array to store scores for each series for the current country iteration
        
        % Loop over each series and create an array of all countries
        % values for the respective series
        for j = 1:size(matrix3D_repeats, 2)
            row = matrix3D_repeats(i, j, :);
            new_row = reshape(row, 1, []); %transpose 
            
            % Adjust to get the correct range
            dataCell = new_row((end - analysis_period + 1):end);
            
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
            ind = unique_indicators{k}; 
            indices = find(strcmp(indicators, ind)); % Find indices for the current indicator
            values = scores_for_country(indices); % Get series scores corresponding to the current indicator
            
            if any(~isnan(values)) % If there are non-NaN values
                nonNaN_values = values(~isnan(values)); % Extract non-NaN values
                sum_values = sum(nonNaN_values); % Sum of non-NaN values
                count = length(nonNaN_values); % Count of non-NaN values
                average = sum_values / count; % Calculate the average score for this indicator
                score_matrix_repeats(i, k, pIndex) = average; % Store the average score in the matrix
            end
        end
    end
end

% Get the number of countries, indicators, and time periods
[num_countries, num_indicators, num_time_periods] = size(score_matrix_repeats);

% Extract the goal numbers from the indicators (the first number before the dot)
goal_numbers = str2double(extractBefore(unique_indicators, '.'));

% Initialize a matrix to hold average scores for each goal and time period
average_scores_by_goal = nan(17, num_time_periods); % There are 17 goals

% Loop over each goal
for g = 1:17
    % Find indices of indicators that belong to this goal
    goal_indices = find(goal_numbers == g);
    
    % Loop over each time period to calculate the average score for the goal
    for t = 1:num_time_periods
        % Extract scores for this goal across all countries for the current time period
        goal_scores = score_matrix_repeats(:, goal_indices, t);
        
        % Calculate the average score (ignoring NaN values)
        average_scores_by_goal(g, t) = mean(goal_scores(:), 'omitnan');
    end
end

% Create goal names 
goal_names = strcat("Goal ", string(1:17));

% Create a table with goal names and average scores for each time period
average_scores_goals_table = array2table(average_scores_by_goal, ...
    'RowNames', goal_names, ...
    'VariableNames', strcat('Score_', string(1:num_time_periods)));

% Save table into another sheet in excel file
writetable(average_scores_goals_table, excelFilename, 'Sheet', 'Goal Results');

% Define year periods 
year_periods = {'2004-2023', '2005-2023', '2006-2023', '2007-2023', ...
                '2008-2023', '2009-2023', '2010-2023', '2011-2023', ...
                '2012-2023', '2013-2023', '2014-2023'};
x_labels = string(year_periods);

% Plot the average scores for each goal across time periods
figure;  
hold on;

colors = turbo(17);  % Using the turbo colormap to create distinction between colour

% Plot for each goal with distinct markers and colors
for g = 1:17
    % Use filled markers for odd-numbered goals and unfilled for even to
    % differentiate
    if mod(g, 2) == 0
        % Even goals: filled markers
        plot(1:num_time_periods, average_scores_by_goal(g, :), '-o', ...
            'DisplayName', goal_names{g}, 'Color', colors(g, :), ...
            'LineWidth', 0.8, 'MarkerSize', 5, 'MarkerFaceColor', colors(g, :)); 
    else
        % Odd goals: unfilled markers
        plot(1:num_time_periods, average_scores_by_goal(g, :), '-x', ...
            'DisplayName', goal_names{g}, 'Color', colors(g, :), ...
            'LineWidth', 0.8, 'MarkerSize', 7, 'MarkerFaceColor', 'none'); 
    end
end


% Finalize the plot
hold off;
xlabel('Analysis Period (Years Prior to 2023)');
ylabel('Average Score');
legend(goal_names, 'Location', 'eastoutside', 'NumColumns', 1); 
title('Average Scores by Goal Across Time Periods');
xlim([1 num_time_periods]);  
grid on;

% Set custom x-axis labels
xticks(1:num_time_periods);            
xticklabels(x_labels); 

% Save the figure
saveas(gcf, 'average_scores_by_goal_plot.png');