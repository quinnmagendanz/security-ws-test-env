var fs = require("fs");
var system = require("system");
var webpage = require("webpage");

var grading = require("./grading");

function main(studentDir) {
    if (studentDir === undefined) {
        console.log("USAGE: phantomjs " + system.args[0] + " student_dir/");
        phantom.exit();
        return;
    }
    var answerPath = studentDir + "/answer-10.html";
    if (!fs.isFile(answerPath)) {
        grading.failed("No answer-10.html");
        phantom.exit();
        return;
    }

    grading.registerTimeout();

    // Initialize the world.
    var graderPassword = grading.randomPassword();
    grading.initUsers(function(auth) {
        testLoggedOut(answerPath, graderPassword);
    }, graderPassword);
}

function testLoggedOut(answerPath, graderPassword) {
    phantom.clearCookies();

    var page = webpage.create();

    grading.openOrDie(page, answerPath, function() {
        // Wait 100ms for it to settle. Shouldn't need to, but meh.
        window.setTimeout(function() {


            // Submit the form. This may break horribly if the student
            // didn't name things identically, but hopefully they
            // started from a copy of the real thing.
            console.log("Entering grader/" + graderPassword + " into form.");

            submitLoginFromClick(page, "grader", graderPassword, function() {
                page.close();

                // Just check if we got a cookie.
                if (grading.getCookie("localhost", "PyZoobarLogin")) {
                    grading.passed("User logged in");
                } else {
                    grading.failed("User not logged in");
                }
                phantom.exit();
            });
        }, 100);
    });
}

function submitLoginFromClick(page, user, pass, cb) {
    var oldUrl = page.url;
    var alerted = false;
    page.onAlert = function(content) {
        if (content.indexOf(pass) > -1) {
            grading.passed("alert contains user password: " + pass);
        } else {
            grading.failed("alert doesn't contain user password: " + pass + ' not in ' + content);
        }
        alerted = true
    };

    page.onLoadFinished = function(status) {
        // PhantomJS is dumb and runs this even on iframe loads. So
        // check that the top-level URL changed.
        if (oldUrl == page.url) return;
        if (!alerted) {
            grading.failed("no alert shown");
        }
        page.onLoadFinished = null;
        cb();
    };
    page.evaluate(function(user, pass, findButton) {
        var f = document.forms["loginform"];
        f.login_username.value = user;
        f.login_password.value = pass;

        var button = findButton(f);
        if (!button)
            throw "Could not find login button";
        button.click();
    }, user, pass, grading.findSubmitButton);
}

main.apply(null, system.args.slice(1));
