

mucimport-bash:
	docker run --rm -it \
		-v `pwd`/cjo_configs/:/cjo_configs:ro \
		-v `pwd`/migrate.lua:/migrate.lua:ro \
		-v `pwd`/output:/output:rw \
		mucimport bash

mucimport-image:
	docker build -t mucimport - < Dockerfile.mucimport

migrate: get_muc_data transform_muc_data upload_muc_data

upload_muc_data:
	rsync -avz --delete output waqas@zeus.jabber.org:.
	ssh -t waqas@zeus.jabber.org sudo cp -r output/conference%2ejabber%2eorg /var/lib/prosody/
	ssh -t waqas@zeus.jabber.org sudo chown -R prosody:prosody /var/lib/prosody/conference%2ejabber%2eorg

transform_muc_data:
	docker run --rm -it \
		-v `pwd`/cjo_configs/:/cjo_configs:ro \
		-v `pwd`/migrate.lua:/migrate.lua:ro \
		-v `pwd`/output:/output:rw \
		mucimport lua migrate.lua

get_muc_data:
	ssh -t -p5437 waqas@hermes.jabber.org 'rm -r ~/cjo_configs ; sudo cp -r /var/isode/ms/pubsub/conference.jabber.org/config ~/cjo_configs ; sudo chown -R `whoami` cjo_configs'
	rsync -avz --delete --exclude 'template-room.xml' --rsh='ssh -p 5437' waqas@hermes.jabber.org:~/cjo_configs/ ./cjo_configs/

jing-image:
	docker build -t jing - < Dockerfile.jing

jing-watch:
	docker run --rm -it -v `pwd`/cjo_configs/:/cjo_configs:ro -v `pwd`/relaxng:/relaxng:ro jing watch java -jar jing.jar -c relaxng/cjo.rng cjo_configs/*.xml
