# TODO: make a setup command that initializes the subtree for gh-pages from scratch.

deploy: syncs3 push

push: build
	cd ./public && git add -A && git commit -m "`date`" && git push

build:
	hugo

syncs3:
	aws s3 sync ./s3 s3://assets.jfo.click/

syncfroms3:
	aws s3 sync s3://assets.jfo.click/ ./s3

resume:
	pandoc ./resume.md -o ./static/jeff_fowler_resume.pdf -V geometry:"top=2cm, bottom=1.5cm, left=4cm, right=4cm"
