% Find indices of valid countries in score_matrix
valid_country_indices = ismember(country_names, country_scores_table.Country);

% Filter the score_matrix based on valid countries
filtered_score_matrix = score_matrix(valid_country_indices, :, :);

% Get the number of valid countries after filtering
numValidCountries = sum(valid_country_indices);

% Initialize a 3D array to store results from each run
n_runs = 10000;
all_scores = nan(numValidCountries, 11, n_runs); % 11 is the number of time periods

for i = 1:n_runs
    % Generate random weights for indicators (normal distribution with mean 1 and std 0.1)
    weights = normrnd(1, 0.1, [numIndicators, 1]);

    % Apply random weights to each indicator in the filtered score matrix
    weighted_scores = bsxfun(@times, filtered_score_matrix, reshape(weights, [1, numIndicators, 1]));

    % Calculate the weighted average score for each country and time period
    final_scores = mean(weighted_scores, 2, 'omitnan');
    final_scores = squeeze(final_scores); % Remove singleton dimensions

    % Store the result of this run in the 3D array
    all_scores(:, :, i) = final_scores;
end

% Calculate the standard deviation of scores across all runs for each time period
std_scores = std(all_scores, 0, 3, 'omitnan');

% Define year periods 
year_periods = {'2004-2023', '2005-2023', '2006-2023', '2007-2023', ...
                '2008-2023', '2009-2023', '2010-2023', '2011-2023', ...
                '2012-2023', '2013-2023', '2014-2023'};
x_labels = string(year_periods);

% Plot the standard deviation of scores for each time period
figure;
hold on;

% Plot each country's standard deviation over all time periods
for t = 1:size(std_scores, 1)
    plot(1:size(std_scores, 2), std_scores(t, :));
end

% Customize the plot
xlabel('Analysis Period');
ylabel('Standard Deviation of Scores with Random Error');
title('Score Sensitivity');
xlim([1, size(std_scores, 2)]);

% Set custom x-axis labels
xticks(1:size(std_scores, 2));
xticklabels(x_labels);

% Save the figure
saveas(gcf, 'sensitivity.png');
hold off;
