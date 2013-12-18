function [S_all, nFailures_all, available] = process_results_labels(trackers, sequences, labels, experiment)

global track_properties;

S_all = cell(length(labels), 1);
nFailures_all = cell(length(labels), 1);

available = true(length(trackers), 1);

for l = 1:length(labels)
    
    label = labels{l};

    print_indent(1);

    print_text('Processing label %s', label);

    label_overlaps = nan(length(trackers), 0);
    label_failures = nan(length(trackers), 0);    
    
    for s = 1:length(sequences)

        filter = query_label(sequences{s}, label);

        if isempty(filter)
            continue;
        end;
        
        print_indent(1);

        groundtruth = get_region(sequences{s}, 1:sequences{s}.length);

        sequence_overlaps = nan(length(trackers), length(filter));
        sequence_failures = nan(length(trackers), track_properties.repeat);

        print_text('Processing sequence %s', sequences{s}.name);

        for t = 1:length(trackers)

            if ~exist(fullfile(trackers{t}.directory, experiment), 'dir')
                print_debug('Warning: Results not available %s', trackers{t}.identifier);
                available(t) = 0;
                continue;
            end;
            
            directory = fullfile(trackers{t}.directory, experiment, sequences{s}.name);

            accuracy = nan(track_properties.repeat, length(filter));
            failures = nan(track_properties.repeat, 1);

            for j = 1:track_properties.repeat

                result_file = fullfile(directory, sprintf('%s_%03d.txt', sequences{s}.name, j));
                trajectory = load_trajectory(result_file);

                if isempty(trajectory)
                    continue;
                end;
                
                if (size(trajectory, 1) < size(groundtruth, 1))
                    trajectory(end+1:size(groundtruth, 1), :) = NaN;
                    trajectory(end+1:size(groundtruth, 1), 4) = 0;
                end;
                
                [~, frames] = estimate_accuracy(trajectory(filter, :), groundtruth(filter, :), 'burnin', track_properties.burnin);

                accuracy(j, :) = frames;

                failures(j) = sum(trajectory(filter, 4) == -2); %estimate_failures(trajectory, sequences{s});

            end;
            
            frames = num2cell(accuracy, 1);
            sequence_overlaps(t, :) = cellfun(@(frame) mean(frame(~isnan(frame))), frames);

            failures(isnan(failures)) = mean(failures(~isnan(failures)));

            sequence_failures(t, :) = failures;

        end;

        if ~isempty(sequence_overlaps)
            label_overlaps = [label_overlaps sequence_overlaps];
        end;
        if ~isempty(sequence_failures)
            label_failures = [label_failures sequence_failures];
        end;

        print_indent(-1);

    end;

    S_all{l} = label_overlaps;
    nFailures_all{l} = label_failures;

    print_indent(-1);
    
end;