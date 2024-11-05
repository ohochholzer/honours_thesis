% Read the CSV file that contains region classification
region_data = readtable('UNSD — Methodology.csv');

% Extract country and region names
country_column = region_data{:, 9}; % 9th column: country names
region_column = region_data{:, 4};   % 4th column: region names

% Create a map from country to region
country_to_region_map = containers.Map(country_column, region_column);

% Remove rows with NaN values in scores and extract corresponding country names
scores_only = country_scores_matrix(:, 3:end); % Scores only, excluding first two columns
scores_only = cell2mat(scores_only); % Convert to numeric matrix
rows_with_nan = any(isnan(scores_only), 2); % Identify rows with NaN values
country_scores_matrix(rows_with_nan, :) = []; % Remove NaN rows
country_names = country_scores_matrix(:, 1); % Retain country names

% Initialize structures to hold region scores and counts
region_scores = containers.Map();  
region_count = containers.Map();    

% Define year periods 
year_periods = {'2004-2023', '2005-2023', '2006-2023', '2007-2023', ...
                '2008-2023', '2009-2023', '2010-2023', '2011-2023', ...
                '2012-2023', '2013-2023', '2014-2023'};
x_labels = string(year_periods);

% Loop over each country and accumulate scores by region 
for i = 1:size(country_scores_matrix, 1)
    country_name = country_names{i};    
    % Process scores by region
    if isKey(country_to_region_map, country_name)
        region_name = country_to_region_map(country_name);
        
        % Initialize region scores if not present
        if ~isKey(region_scores, region_name)
            region_scores(region_name) = zeros(1, numPeriods);
            region_count(region_name) = 0; % Initialize country count for the region
        end
        
        % Add the country's scores to the region's total scores
        region_total_scores = region_scores(region_name);
        for pIndex = 1:numPeriods
            region_total_scores(pIndex) = region_total_scores(pIndex) + country_scores_matrix{i, pIndex + 2};
        end
        
        % Update the region's total scores and increment country count
        region_scores(region_name) = region_total_scores;
        region_count(region_name) = region_count(region_name) + 1;
    end
end

% Calculate the average scores for each region
region_names = keys(region_scores);
region_names = cell(region_names);  % Convert keys to cell array
region_names = region_names(~cellfun('isempty', region_names)); % Filter out empty entries
num_regions = length(region_names);
region_average_scores = zeros(num_regions, numPeriods);

for rIndex = 1:num_regions
    region_name = region_names{rIndex};
    % Calculate the average score for the region
    region_average_scores(rIndex, :) = region_scores(region_name) ./ region_count(region_name);
end

% Create a new table for region scores
region_scores_table = array2table(region_average_scores, 'VariableNames', x_labels, 'RowNames', region_names);

% Save table into another sheet in the Excel file
writetable(region_scores_table, excelFilename, 'Sheet', 'Region Averages');

% Plot the average scores for each region
figure;
hold on;
for rIndex = 1:num_regions
    plot(1:numPeriods, region_average_scores(rIndex, :), '-o', 'DisplayName', region_names{rIndex});
end

% Configure plot appearance
xlabel('Analysis Period');
ylabel('Average Score');
title('Average Scores by Region');
legend('show', 'Location', 'southwest');
xlim([1 numPeriods]);
xticks(1:numPeriods);             
xticklabels(x_labels); 
xtickangle(45); % Rotate x-tick labels
grid on;
hold off;

% Save the figure
saveas(gcf, 'region_scores_plot.png');
