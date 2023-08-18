const dragDrop = require('cytoscape-compound-drag-and-drop')
import cytoscape from "cytoscape"


export function setupDragAndDrop(cy) {
    const options = {
        grabbedNode: (node) => {
            const isOriginalNode = node.isChild() && (node.parent().data('original_node_id') === node.id());
            return !isOriginalNode;
        },

        dropTarget: (dropTarget, grabbedNode) => dropTarget.isParent(),
        
        dropSibling: (dropSibling, grabbedNode) => false,
        
        newParentNode: (grabbedNode, dropSibling) => dropSibling,
        
        boundingBoxOptions: {
          includeOverlays: false,
          includeLabels: true
        },

        overThreshold: 10,
        
        outThreshold: 10
    };

    cytoscape.use(dragDrop);

    cy.compoundDragAndDrop(options);
}


