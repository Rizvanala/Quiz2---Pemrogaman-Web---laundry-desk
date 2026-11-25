(function () {
    var saved = null;
    try { saved = localStorage.getItem("theme"); } catch (e) { saved = null; }
    var dark = saved ? saved === "dark" : window.matchMedia("(prefers-color-scheme: dark)").matches;
    document.documentElement.setAttribute("data-theme", dark ? "dark" : "light");

    document.addEventListener("DOMContentLoaded", function () {
        var button = document.getElementById("theme-toggle");
        if (!button) { return; }
        function paint() {
            var isDark = document.documentElement.getAttribute("data-theme") === "dark";
            button.textContent = isDark ? "\u2600" : "\u263E";
            button.setAttribute("aria-label", isDark ? "Switch to the light theme" : "Switch to the dark theme");
        }
        paint();
        button.addEventListener("click", function () {
            var next = document.documentElement.getAttribute("data-theme") === "dark" ? "light" : "dark";
            document.documentElement.setAttribute("data-theme", next);
            try { localStorage.setItem("theme", next); } catch (e) { /* private mode */ }
            paint();
        });
    });
})();
