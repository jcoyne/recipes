# Recipe images are stored as AVIF. Registering the type also lets Propshaft's
# development file watcher notice newly imported images without a restart.
Mime::Type.register "image/avif", :avif
