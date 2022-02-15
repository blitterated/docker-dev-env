#!/bin/sh
CONT_ID=$(docker create dde)
docker export $CONT_ID | docker import - dde_flat
docker rm $CONT_ID
