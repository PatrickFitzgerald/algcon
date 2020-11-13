
clear all
clc

filename = 'code_source.m';
snippet = fileread(filename);

ac = AlgorithmConstructor();
% id = ac.addSnippet(snippet)
ids = ac.addSnippets(snippet)

ac.assume_conversion(BasicUnits.DURATION('v.abc.xyz_sec'))



