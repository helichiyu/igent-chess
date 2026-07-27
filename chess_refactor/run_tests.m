function results = run_tests()
%RUN_TESTS Execute unit tests for the refactored implementation.
results = runtests("tests");
disp(table(results));
end
