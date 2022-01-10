package de.solidblocks.base

open class TenantReference(cloud: String, environment: String, val tenant: String) :
    EnvironmentReference(cloud, environment) {
    fun toService(service: String) = ServiceReference(cloud, environment, tenant, service)
}
