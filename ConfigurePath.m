function ConfigurePath()
    cd Core
    addpath(GetFullPath('.'));
    cd ..
    addpath(GetFullPath('Data'));
end