
clear all
clc

filename = 'code_source.m';
snippet = fileread(filename);

ac = AlgorithmConstructor();
% id = ac.addSnippet(snippet)
ids = ac.addSnippets(snippet)





