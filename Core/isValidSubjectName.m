function [ valid, subject_name ] = isValidSubjectName( subject_name )
    valid = 0;
    if isempty(subject_name)
        subject_name = input('Please enter the participant''s name: ', 's');
    end
    if isempty(subject_name)
        fprintf('A participant name must be provided\n');
        return
    elseif ~isempty(regexp(subject_name, '[\W]+', 'start'))
        fprintf('Sorry, the name can only contain letters, numbers, or underscores\n');
        return
    end
    valid = 1;
end

