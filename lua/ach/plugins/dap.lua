-- The debugger: nvim-dap, its interface, values drawn beside the code, and
-- the adapters from Mason and for Python. All of them load with nvim-dap, on
-- its first key or command, or when a language's plugin asks for it; ach.dap
-- sets them up. nvim-dap's last release is from March 2025 and dap-ui's from
-- March 2024, and neither nvim-dap-virtual-text nor nvim-dap-python releases
-- at all, so each is pinned to the commit whose source was read. mason-nvim-dap
-- releases, and follows its 2.x line.
return {
  {
    "mfussenegger/nvim-dap",
    commit = "cfa2d58f4537aca6ca83e2de1a0d9f1491121264",
    dependencies = {
      { "rcarriga/nvim-dap-ui", commit = "cc9dd33aade7f20bae414d0cba163bc60d4d4b43" },
      { "nvim-neotest/nvim-nio", commit = "edcc181a875301dd21840189aa2f2f9ad69fc172" },
      { "theHamsta/nvim-dap-virtual-text", commit = "fbdb48c2ed45f4a8293d0d483f7730d24467ccb6" },
      { "jay-babu/mason-nvim-dap.nvim", version = "^2", dependencies = { "mason-org/mason.nvim" } },
      { "mfussenegger/nvim-dap-python", commit = "1808458eba2b18f178f990e01376941a42c7f93b" },
    },
    cmd = {
      "DapContinue",
      "DapToggleBreakpoint",
      "DapClearBreakpoints",
      "DapToggleRepl",
      "DapStepOver",
      "DapStepInto",
      "DapStepOut",
      "DapPause",
      "DapTerminate",
      "DapDisconnect",
      "DapRestartFrame",
      "DapNew",
      "DapEval",
      "DapSetLogLevel",
      "DapShowLog",
    },
    keys = function()
      local keys = {}
      for _, k in ipairs(require("ach.dap").keys) do
        keys[#keys + 1] = { k[1], k[2], desc = k[3], mode = k[4] }
      end
      return keys
    end,
    config = function() require("ach.dap").setup() end,
  },
}
