#!/bin/sh -x
git checkout gh-pages
git merge -X theirs master -m "Merge branch 'master' into gh-pages"
browserify index.coffee -t coffeeify -t browserify-commit-sha > bundle.js
git commit bundle.js -m "Regenerate bundle.js using deploy.sh"
git checkout master
