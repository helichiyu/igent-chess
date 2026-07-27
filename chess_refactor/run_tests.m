function results = run_tests()
%RUN_TESTS Execute unit tests from this project regardless of MATLAB's test cwd.
projectRoot = fileparts(mfilename("fullpath"));
addpath(projectRoot);
results = runtests("tests");
disp(table(results));
end
