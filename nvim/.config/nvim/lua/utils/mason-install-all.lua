local M = {}

M.get_packages = function()
    local lang_config = require("lang")
    return lang_config.mason_packages or {}
end

M.install_all = function()
    local mr = require("mason-registry")

    -- Headless (installer-triggered) path: refresh() with no callback runs
    -- synchronously (run_blocking), so the one-shot
    -- `nvim --headless -c "MasonInstallAll" -c "qall"` from setup.sh blocks to
    -- completion instead of exiting before the async registry fetch finishes.
    if #vim.api.nvim_list_uis() == 0 then
        mr.refresh()
        local packages = M.get_packages()
        local to_install = {}

        for _, package_name in ipairs(packages) do
            if mr.has_package(package_name) then
                local pkg = mr.get_package(package_name)
                if not pkg:is_installed() then
                    table.insert(to_install, package_name)
                end
            else
                vim.notify("Warning: Mason doesn't have package: " .. package_name, vim.log.levels.WARN)
            end
        end

        if #to_install > 0 then
            vim.cmd("MasonInstall " .. table.concat(to_install, " "))
            vim.notify(
                "Mason: Installing " .. #to_install .. " packages: " .. table.concat(to_install, ", "),
                vim.log.levels.INFO
            )
        else
            vim.notify("Mason: All packages already installed", vim.log.levels.INFO)
        end
        return
    end

    mr.refresh(function()
        local packages = M.get_packages()
        local to_install = {}

        for _, package_name in ipairs(packages) do
            if mr.has_package(package_name) then
                local pkg = mr.get_package(package_name)
                if not pkg:is_installed() then
                    table.insert(to_install, package_name)
                end
            else
                vim.notify("Warning: Mason doesn't have package: " .. package_name, vim.log.levels.WARN)
            end
        end

        if #to_install > 0 then
            vim.cmd("MasonInstall " .. table.concat(to_install, " "))
            vim.notify(
                "Mason: Installing " .. #to_install .. " packages: " .. table.concat(to_install, ", "),
                vim.log.levels.INFO
            )
        else
            vim.notify("Mason: All packages already installed", vim.log.levels.INFO)
        end
    end)
end

vim.api.nvim_create_user_command("MasonInstallAll", function()
    M.install_all()
end, {
    desc = "Install all Mason packages defined in language configs",
})

return M
