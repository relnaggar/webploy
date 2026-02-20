readonly STACK_NAME="prod"

get_container_id() {
  local service="${1:-app}"
  echo "$(docker ps --filter "name=${service}" --format "{{.ID}}")"
}
