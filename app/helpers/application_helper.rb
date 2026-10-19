module ApplicationHelper
  def nav_link(label, path, section)
    active = controller_name == section
    link_to label, path, class: ["nav-link", ("active" if active)], "aria-current": (active ? "page" : nil)
  end

  def presence_badge(present)
    case present
    when true  then tag.span("Yes", class: "badge badge-yes")
    when false then tag.span("No", class: "badge badge-no")
    else tag.span("-", class: "badge")
    end
  end
end
