/// Say goodbye, close the socket and free the buffers.
stop();
buffer_delete(out_buf);
buffer_delete(tag_buf);
