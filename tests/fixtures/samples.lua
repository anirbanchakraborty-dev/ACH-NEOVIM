-- One sample file per entry in lua/ach/languages.lua, keyed by entry name.
-- open is the path of the file to open, text is its content, and extra holds
-- any other files the language needs beside it, such as go.mod. Where the
-- language has a formatter, one line is misformatted on purpose; where it has
-- a linter, one warning is planted. The comment above each sample names both.
local M = {}

-- Tailwind's server starts only in a folder its configuration marks, and
-- ESLint's only where a configuration of its own is found.
local tailwind = { ["tailwind.config.js"] = "module.exports = { content: ['./**/*'] };\n" }
local eslint = { ["eslint.config.mjs"] = "export default [];\n" }

M.samples = {
  -- Editor and shell -------------------------------------------------------
  -- stylua: the spacing around "=".
  lua = { open = "sample.lua", text = [[
local x   =  1
return x
]] },
  vim = { open = "sample.vim", text = [[
let g:sample = 1
]] },
  -- shfmt: the unindented echo.
  sh = { open = "sample.sh", text = [[
#!/usr/bin/env bash
if [ -n "$1" ]; then
echo "$1"
fi
]] },
  -- fish_indent: the unindented echo.
  fish = { open = "config.fish", text = [[
if true
echo hello
end
]] },
  nushell = { open = "sample.nu", text = [[
def main [] { print "hello" }
]] },
  powershell = { open = "sample.ps1", text = [[
Write-Output "hello"
]] },
  perl = { open = "sample.pl", text = [[
use strict;
print "hello\n";
]] },
  awk = { open = "sample.awk", text = [[
{ print $1 }
]] },
  jq = { open = "sample.jq", text = [[
.name
]] },

  -- Systems ----------------------------------------------------------------
  -- clang-format: the whole function on one line.
  c = { open = "sample.c", text = [[
int main(void){return 0;}
]] },
  rust = {
    open = "src/main.rs",
    text = [[
fn main() {
    println!("hello");
}
]],
    extra = { ["Cargo.toml"] = '[package]\nname = "sample"\nversion = "0.1.0"\nedition = "2021"\n' },
  },
  -- gofumpt: the unindented call. golangci-lint: os.Remove's error is never checked.
  go = {
    open = "main.go",
    text = [[
package main

import "os"

func main() {
os.Remove("sample.tmp")
}
]],
    extra = { ["go.mod"] = "module example.com/sample\n\ngo 1.22\n" },
  },
  zig = { open = "main.zig", text = [[
pub fn main() void {}
]] },
  swift = { open = "main.swift", text = [[
print("hello")
]] },
  fortran = { open = "sample.f90", text = [[
program sample
  print *, "hello"
end program sample
]] },
  asm = { open = "sample.s", text = [[
.text
.globl main
main:
  ret
]] },
  llvm = { open = "sample.ll", text = [[
; ModuleID = 'sample'
define i32 @main() {
  ret i32 0
}
]] },
  mlir = { open = "sample.mlir", text = [[
func.func @main() {
  return
}
]] },
  tablegen = { open = "sample.td", text = [[
class Sample<int n> {
  int value = n;
}
]] },
  linker = { open = "sample.ld", text = [[
SECTIONS
{
  .text : { *(.text) }
}
]] },
  devicetree = { open = "sample.dts", text = [[
/dts-v1/;
/ {
  model = "sample";
};
]] },
  kconfig = { open = "Kconfig", text = [[
config SAMPLE
	bool "Sample option"
]] },

  -- Hardware description --------------------------------------------------
  -- verible: the whole module on one line.
  systemverilog = { open = "sample.sv", text = [[
module sample(input logic a,output logic y);assign y=a;endmodule
]] },
  -- vhdl_ls starts only beside a vhdl_ls.toml naming the files.
  vhdl = {
    open = "sample.vhd",
    text = [[
entity sample is
end entity sample;
]],
    extra = { ["vhdl_ls.toml"] = '[libraries]\nsample.files = ["sample.vhd"]\n' },
  },
  veryl = { open = "sample.veryl", text = [[
module Sample {
    var a: logic;
}
]] },
  bsv = { open = "Sample.bsv", text = [[
package Sample;
endpackage
]] },
  firrtl = {
    open = "sample.fir",
    text = [[
FIRRTL version 3.3.0
circuit Sample :
  module Sample :
    input a : UInt<1>
]],
  },
  -- tclint: an expression with substitutions that is not braced.
  tcl = { open = "sample.tcl", text = [[
set a 1
set b 2
set c [expr $a + $b]
]] },

  -- Build systems ------------------------------------------------------------
  -- cmake-format: the spaces inside add_executable. cmakelint: "Project" in mixed case.
  cmake = {
    open = "CMakeLists.txt",
    text = [[
cmake_minimum_required(VERSION 3.20)
Project(sample)
add_executable( sample   main.c )
]],
  },
  make = { open = "Makefile", text = "all:\n\techo hello\n" },
  meson = { open = "meson.build", text = [[
project('sample', 'c')
]] },
  ninja = { open = "build.ninja", text = [[
rule cc
  command = cc -c $in -o $out
]] },
  just = { open = "justfile", text = [[
default:
    echo hello
]] },
  -- buildifier: the call on one line, with no spaces around "=".
  starlark = { open = "BUILD", text = [[
cc_binary(name="sample",srcs=["main.c"])
]] },

  -- Python, JVM, .NET ---------------------------------------------------------
  -- ruff: the spacing and quotes in the dictionary.
  python = { open = "sample.py", text = [[
import os

x = {  'a':1 }
print(os.name, x)
]] },
  java = {
    open = "Sample.java",
    text = [[
public class Sample {
    public static void main(String[] args) {
    }
}
]],
  },
  -- ktlint: the trailing semicolon, both as a lint warning and as the format fix.
  kotlin = { open = "sample.kt", text = [[
fun main() {
    val x = 1;
    println(x)
}
]] },
  scala = {
    open = "Sample.scala",
    text = [[
object Sample {
  def main(args: Array[String]): Unit = println("hello")
}
]],
  },
  groovy = { open = "sample.groovy", text = [[
println "hello"
]] },
  clojure = { open = "sample.clj", text = [[
(ns sample)
(defn f [x] x)
]] },
  -- csharpier: the class on one line.
  dotnet = { open = "Sample.cs", text = [[
class Sample{static void Main(){}}
]] },

  -- Functional ------------------------------------------------------------------
  -- fourmolu: the spacing around "=" in main. hlint: a redundant if.
  haskell = {
    open = "Main.hs",
    text = [[
module Main where

f :: Bool -> Bool
f x = if x then True else False

main :: IO ()
main  =  print (f True)
]],
  },
  -- ocamlformat, which formats only inside a project with .ocamlformat: the spacing around "=".
  ocaml = {
    open = "sample.ml",
    text = [[
let x  =  1
]],
    extra = { [".ocamlformat"] = "profile = default\n" },
  },
  elixir = { open = "sample.ex", text = [[
defmodule Sample do
end
]] },
  erlang = { open = "sample.erl", text = [[
-module(sample).
]] },
  -- gleam format: the expression on one line with no spaces.
  gleam = { open = "sample.gleam", text = [[
pub fn main() {
1+1
}
]] },
  -- elm-format: the two-space indent, which it makes four.
  elm = { open = "Main.elm", text = [[
module Main exposing (main)

import Html

main =
  Html.text "hello"
]] },
  lean = { open = "Sample.lean", text = [[
def x : Nat := 1
]] },
  julia = { open = "sample.jl", text = [[
println("hello")
]] },
  -- The comment is what tells Neovim this is R rather than Rexx.
  r = { open = "sample.R", text = [[
# sample
x <- 1
]] },
  -- nixfmt: the whole expression on one line. statix: a = a, which inherit says better.
  nix = { open = "sample.nix", text = [[
let a = 1; in { a = a; }
]] },

  -- Web --------------------------------------------------------------------------
  -- prettier: the object's spacing and the missing semicolons.
  typescript = {
    open = "sample.ts",
    text = [[
const x = {a:1}
export default x
]],
    extra = vim.tbl_extend("error", tailwind, eslint),
  },
  -- prettier: the spaces between the attributes.
  html = {
    open = "sample.html",
    text = [[
<!doctype html>
<p   class="a">hello</p>
]],
    extra = tailwind,
  },
  -- prettier: the rule on one line.
  css = {
    open = "sample.css",
    text = [[
a{color:red}
]],
    extra = tailwind,
  },
  -- prettier: the single quotes and the missing semicolon.
  vue = {
    open = "Sample.vue",
    text = [[
<template><p>{{ msg }}</p></template>
<script setup>
const msg = 'hello'
</script>
]],
    extra = tailwind,
  },
  svelte = {
    open = "Sample.svelte",
    text = [[
<script>
  let name = "world";
</script>
<p>Hello {name}</p>
]],
    extra = tailwind,
  },
  astro = {
    open = "sample.astro",
    text = [[
---
const name = "world";
---
<p>Hello {name}</p>
]],
    extra = tailwind,
  },
  -- The *ngIf is what tells Neovim this is an Angular template. prettier: the
  -- spaces between the attributes.
  angular = {
    open = "app.component.html",
    text = [[
<div   *ngIf="shown"   class="a">hello</div>
]],
    extra = tailwind,
  },
  -- prettier: the spaces between the attributes.
  ember = { open = "sample.hbs", text = [[
<p   class="a">{{this.message}}</p>
]] },
  -- prettier: the type on one line.
  graphql = { open = "schema.graphql", text = [[
type Query{hello:String}
]] },
  -- php-cs-fixer: the spacing in the function. phpcs: no file doc comment.
  php = { open = "sample.php", text = [[
<?php

function  f( $x ){return $x;}
]] },
  -- twiggy fails to start with no workspace folder, which composer.json marks.
  twig = {
    open = "sample.html.twig",
    text = [[
<p>{{ name }}</p>
]],
    extra = { ["composer.json"] = "{}\n" },
  },
  -- rubocop: the spacing and the hash-rocket in the hash.
  ruby = { open = "sample.rb", text = [[
x = {  :a=>1 }
puts x
]] },
  -- dart format: the function on one line.
  dart = { open = "main.dart", text = [[
void main(){print('hello');}
]] },
  prisma = { open = "schema.prisma", text = [[
datasource db {
  provider = "sqlite"
  url      = "file:dev.db"
}
]] },
  solidity = {
    open = "Sample.sol",
    text = [[
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Sample {}
]],
  },

  -- Data, config and infrastructure -----------------------------------------------
  -- prettier: the object on one line with no spaces.
  json = { open = "sample.json", text = [[
{"a":1}
]] },
  -- prettier: the spaces after the colon.
  yaml = { open = "sample.yaml", text = [[
a:   1
]] },
  -- taplo: the spacing around "=".
  toml = { open = "sample.toml", text = [[
a  =  1
]] },
  xml = { open = "sample.xml", text = [[
<?xml version="1.0"?>
<root/>
]] },
  ini = { open = "sample.ini", text = [[
[section]
key = value
]] },
  csv = { open = "sample.csv", text = [[
a,b
1,2
]] },
  -- sqlfluff, both as formatter and linter: the double space, and keywords in
  -- mixed case. There is deliberately no .sqlfluff beside it, because the
  -- configuration must name the dialect itself, as it must for any SQL file.
  sql = { open = "sample.sql", text = [[
SELECT a  from t
]] },
  -- buf format: the message on one line.
  proto = { open = "sample.proto", text = [[
syntax = "proto3";
message Sample{string name=1;}
]] },
  thrift = { open = "sample.thrift", text = [[
struct Sample {
  1: string name
}
]] },
  -- hadolint: an image pinned to "latest".
  docker = { open = "Dockerfile", text = [[
FROM ubuntu:latest
]] },
  -- tflint: a variable that is declared and never used.
  terraform = { open = "main.tf", text = [[
variable "unused" {}
]] },
  helm = {
    open = "chart/templates/configmap.yaml",
    text = [[
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}
]],
    extra = { ["chart/Chart.yaml"] = "apiVersion: v2\nname: sample\nversion: 0.1.0\n" },
  },
  ansible = {
    open = "playbooks/site.yml",
    text = [[
- hosts: all
  tasks:
    - name: Ping
      ansible.builtin.ping:
]],
  },
  rego = { open = "sample.rego", text = [[
package sample

allow := true
]] },
  dot = { open = "sample.dot", text = [[
digraph G { a -> b }
]] },
  -- Harper: the repeated "the".
  git = { open = "COMMIT_EDITMSG", text = [[
Add the sample

This is the the body.
]] },

  -- Shaders ------------------------------------------------------------------------
  glsl = { open = "sample.glsl", text = [[
#version 330 core
void main() {}
]] },
  hlsl = { open = "sample.hlsl", text = [[
float4 main() : SV_Target { return 0; }
]] },
  wgsl = {
    open = "sample.wgsl",
    text = [[
@fragment
fn main() -> @location(0) vec4<f32> {
  return vec4<f32>(1.0);
}
]],
  },

  -- Prose ------------------------------------------------------------------------
  -- prettier: the "*" bullet, which it makes "-". markdownlint: "#No space",
  -- a heading with no space after the hash.
  markdown = { open = "sample.md", text = [[
# Sample

#No space

* item
]] },
  tex = { open = "sample.tex", text = [[
\documentclass{article}
\begin{document}
Hello.
\end{document}
]] },
  -- typstyle: the spacing around "=".
  typst = { open = "sample.typ", text = [[
#let x  =  1
]] },
  lilypond = { open = "sample.ly", text = [[
\version "2.24.0"
\relative c' {
  c4 d e f
}
]] },
  -- Harper: the repeated "the".
  text = { open = "sample.txt", text = [[
This is the the sample.
]] },
}

-- Writes a sample and its extra files under dir and returns the full path of
-- the file to open. Folders in a path are created as needed.
function M.write(dir, name)
  local sample = assert(M.samples[name], "no sample for " .. name)
  local files = vim.tbl_extend("force", sample.extra or {}, { [sample.open] = sample.text })
  for path, text in pairs(files) do
    local full = dir .. "/" .. path
    vim.fn.mkdir(vim.fs.dirname(full), "p")
    local f = assert(io.open(full, "w"))
    f:write(text)
    f:close()
  end
  return dir .. "/" .. sample.open
end

return M
