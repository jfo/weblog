# TODO: make a setup command that initializes the subtree for gh-pages from scratch.

serve:
	HUGO_ENV=development hugo serve -D

deploy: syncs3 push

push: build
	cd ./public && git add -A && git commit -m "`date`" && git push

build:
	hugo

syncs3:
	aws s3 sync ./static/s3 s3://assets.jfo.click/

syncfroms3:
	aws s3 sync s3://assets.jfo.click/ ./static/s3

resume:
	pandoc ./resume.md -o ./static/jeff_fowler_resume.pdf -V geometry:"top=2cm, bottom=1.5cm, left=4cm, right=4cm"

serve:
	hugo serve --buildDrafts

initsubtree:
	# git checkout --orphan gh-pages
	# git reset --hard
	# git commit --allow-empty -m "Initializing gh-pages branch"
	# git push origin gh-pages
	# git checkout master
	rm -rf public
	git worktree prune
	git worktree add -B gh-pages public origin/gh-pages
