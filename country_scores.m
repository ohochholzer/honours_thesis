% Transpose the array of geographic area names to create a column vector
country_names = transpose(geoAreaNames);

% Read the CSV file for country codes
methodology_data = readtable('UNSD — Methodology.csv');

% Extract country codes and country names
country_codes_column = methodology_data{:, 12}; % 12th column contains country codes
country_names_methodology = methodology_data{:, 9}; % 9th column contains country names

% Create a map from country names to country codes
name_to_code_map = containers.Map(country_names_methodology, country_codes_column);

% Load the CLASS.xlsx to get countries that are World Bank member countries or countries with populations of 30,000 or more
class_data = readtable('CLASS.xlsx');

% Extract country codes from CLASS.xlsx
country_codes_class = class_data{:, 2};

% Initialize a matrix to hold country names and their scores for each analysis period
numCountries = size(score_matrix, 1);
country_scores_matrix = cell(numCountries, numPeriods + 2); % +2 for country names and country codes

% Fill in country names
country_scores_matrix(:, 1) = country_names;

% Initialize country codes using a loop
country_codes = cell(numCountries, 1); % Initialize country codes array
for i = 1:numCountries
    country_name = country_names{i};
    if isKey(name_to_code_map, country_name)
        country_codes{i} = name_to_code_map(country_name);
    else
        country_codes{i} = ''; % Assign empty string if not found
    end
end

% Fill in the country codes
country_scores_matrix(:, 2) = country_codes;

% Loop over each time period and fill in the scores
for pIndex = 1:numPeriods
    % Extract the 2D score matrix for the current time period
    current_score_matrix = score_matrix(:, :, pIndex);
    
    % Initialize an array to hold the total scores for each country
    country_totals = nan(size(current_score_matrix, 1), 1);
    
    % Loop over each country
    for i = 1:size(current_score_matrix, 1)
        country_scores_cell = current_score_matrix(i, :);
        new_scores = reshape(country_scores_cell, 1, []);
        
        if any(~isnan(new_scores))
            non_Nan_scores = new_scores(~isnan(new_scores));
            % Only include countries with scores for more than 50 indicators
            if length(non_Nan_scores) > 50
                total_score = mean(non_Nan_scores);
                % Store the total score in the country_totals array
                country_totals(i) = total_score;
            end
        end
    end
    
    % Fill in the scores for the current time period
    country_scores_matrix(:, pIndex + 2) = num2cell(country_totals);
end


% Convert cell array to table for better display
country_scores_table = cell2table(country_scores_matrix, 'VariableNames', ...
    ['Country', 'CountryCode', strcat('Score_', string(analysis_periods))]);

% Filter the country scores table to include only valid country codes from CLASS.xlsx
valid_indices_class = ismember(country_scores_table.CountryCode, country_codes_class);

% Filter the country scores table to include only countries present in the UNSD methodology file
valid_indices_unsd = ismember(country_scores_table.Country, country_names_methodology);

% Combine both filters
valid_indices = valid_indices_class & valid_indices_unsd;

% Apply the filter to the scores table
country_scores_table = country_scores_table(valid_indices, :);

% Save the table to an Excel file
excelFilename = 'Results.xlsx';
writetable(country_scores_table, excelFilename, 'Sheet', 'Country Scores');

% Sort scores from the 20-year analysis period in descending order
first_score_column = country_scores_table{:, 3}; % Extract the last column for sorting

% If the scores are not numeric, convert them
if iscell(first_score_column)
    first_score_column = cellfun(@str2double, first_score_column);
end

% Sort the table by the last score column in descending order
[~, sortOrder] = sort(first_score_column, 'descend');
sorted_country_scores_table = country_scores_table(sortOrder, :);

% Save the sorted table to another sheet in the same Excel file
writetable(sorted_country_scores_table, excelFilename, 'Sheet', 'Country Scores (sorted)');

% Identify and print countries that were removed
removed_countries = country_names(~ismember(country_names, country_scores_table.Country)); 

if ~isempty(removed_countries)
    fprintf('Removed countries\n');
    % Print each country on a new line
    for i = 1:length(removed_countries)
        fprintf('%s\n', removed_countries{i});
    end
end

