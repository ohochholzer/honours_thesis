% Load the CLASS.xlsx file
class_data = readtable('CLASS.xlsx');

% Extract country codes and income groups
country_codes_class = class_data{:, 2};
income_groups = class_data{:, 4};

% Create a map from country codes to income groups
code_to_income_map = containers.Map(country_codes_class, income_groups);

% Remove rows with NaN values in scores and extract corresponding country names
scores_only = country_scores_matrix(:, 3:end); % Scores only, excluding first two columns
scores_only = cell2mat(scores_only); % Convert to numeric matrix
rows_with_nan = any(isnan(scores_only), 2); % Identify rows with NaN values
country_scores_matrix(rows_with_nan, :) = []; % Remove NaN rows
country_names = country_scores_matrix(:, 1); % Retain country names

% Define year periods 
year_periods = {'2004-2023', '2005-2023', '2006-2023', '2007-2023', ...
                '2008-2023', '2009-2023', '2010-2023', '2011-2023', ...
                '2012-2023', '2013-2023', '2014-2023'};
x_labels = string(year_periods);

% Initialize a cell array to hold income groups corresponding to countries in country_scores_matrix
numCountries = size(country_names);
income_group_column = cell(numCountries);  

% Fill the income group column based on the country codes in country_scores_matrix
for i = 1:numCountries
    country_code = country_scores_matrix{i, 2};  
    if isKey(code_to_income_map, country_code)
        income_group_column{i} = (code_to_income_map(country_code));
    end
end

% Filter out empty entries from income_group_column
income_group_column = income_group_column(~cellfun('isempty', income_group_column));

% Get unique income groups
unique_income_groups = unique(income_group_column);

% Initialize a matrix to hold average scores for each income group and time period
average_scores_by_income = nan(numel(unique_income_groups), numPeriods);

% Loop over each income group and calculate the average scores
for g = 1:numel(unique_income_groups)
    group = unique_income_groups{g};
    
    % Find the indices of countries in this income group
    group_indices = strcmp(income_group_column, group);
    
    % Loop over each time period to calculate the average score for the group
    for pIndex = 1:numPeriods
        % Extract the scores for countries in the current income group
        current_scores = cell2mat(country_scores_matrix(group_indices, pIndex + 2)); % Fill in the correct index
        % Calculate the average score (ignoring NaN values)
        if ~isempty(current_scores)
            average_scores_by_income(g, pIndex) = mean(current_scores, 'omitnan');
        end
    end
end

% Create a table with income groups and average scores
average_scores_income_table = array2table(average_scores_by_income, ...
    'RowNames', unique_income_groups, ...
    'VariableNames', strcat('Score_', string(1:numPeriods)));

% Define the desired order of income groups
desired_order = {'High income', 'Upper middle income', 'Lower middle income', 'Low income'};

% Get the current row names (income groups)
current_row_names = average_scores_income_table.Properties.RowNames;

% Create an index array to reorder the table based on the desired order
[~, order_indices] = ismember(desired_order, current_row_names);

% Ensure that all desired orders are found in current row names
if all(order_indices > 0)
    % Reorder the table using the order_indices
    reordered_table = average_scores_income_table(order_indices(order_indices > 0), :);

    % Update the RowNames of the new table to match the desired order
    reordered_table.Properties.RowNames = desired_order;
    
    % Optionally, replace the original table with the reordered one
    average_scores_income_table = reordered_table;
end

% Save table into another sheet in excel file
writetable(average_scores_income_table, excelFilename, 'Sheet', 'Income Group Averages');

% Plot the average scores for each income group across time periods
figure;
hold on;
plot1 = plot(1:numPeriods, average_scores_by_income(1, :), '-o', "DisplayName", "High income");
plot2 = plot(1:numPeriods, average_scores_by_income(2, :), '-o', "DisplayName", "Low income");
plot3 = plot(1:numPeriods, average_scores_by_income(3, :), '-o', "DisplayName", "Lower middle income");
plot4 = plot(1:numPeriods, average_scores_by_income(4, :), '-o', "DisplayName", "Upper middle income");
xlabel('Analysis Period');
ylabel('Average Score');
legend([plot1, plot4, plot3, plot2], 'Location', 'Best');
title('Average Scores by Income Group Across Time Periods');
xlim([1 numPeriods]);
grid on;

xticks(1:numPeriods);             
xticklabels(x_labels); 
xtickangle(45); % Rotate x-tick labels

hold off;

% Save the figure
saveas(gcf, 'scores_by_income_graph.png');
