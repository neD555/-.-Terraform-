output "mysql_fqdn" {
  value = yandex_mdb_mysql_cluster.mysql.host[0].fqdn
}

output "mysql_db" {
  value = yandex_mdb_mysql_database.app_db.name
}

output "mysql_user" {
  value = yandex_mdb_mysql_user.app_user.name
}
